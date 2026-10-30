# frozen_string_literal: true

describe DiscourseFingerprint::FingerprintController do
  let(:user) { Fabricate(:user) }

  describe "#index" do
    let(:fingerprint_params) do
      { visitor_id: "abc", version: "1.0.0", data: { foo: "bar", audio: "baz" }.to_json }
    end

    context "when checking fingerprints for automatic silencing" do
      before { sign_in(user) }

      it "silences matching users without recording or exposing a reason" do
        user.update!(trust_level: 0)
        existing_post = Fabricate(:post, user: user)
        FlaggedFingerprint.create!(value: "abc", silenced: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).to be_silenced
        expect(user.silenced_till).to be > 100.years.from_now
        expect(user.silence_reason).to be_blank
        expect(user.silenced_record).to be_present
        expect(user.silenced_record.acting_user_id).to eq(Discourse::SYSTEM_USER_ID)
        expect(user.silenced_record.details).to be_blank
        expect(existing_post.reload).not_to be_hidden

        json = UserSerializer.new(user, scope: Guardian.new(user), root: false).as_json
        expect(json[:silence_reason]).to be_blank
      end

      it "does not silence users whose fingerprints do not match" do
        FlaggedFingerprint.create!(value: "other", silenced: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_silenced
        expect(user.silenced_record).to be_nil
      end

      it "does not silence users when the matching fingerprint is only hidden" do
        FlaggedFingerprint.create!(value: "abc", hidden: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_silenced
      end

      it "preserves an existing silence and its reason" do
        UserSilencer.new(
          user,
          Discourse.system_user,
          reason: "Existing moderation reason",
          keep_posts: true,
        ).silence
        FlaggedFingerprint.create!(value: "abc", silenced: true)
        history_id = user.silenced_record.id

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).to be_silenced
        expect(user.silenced_record.id).to eq(history_id)
        expect(user.silence_reason).to eq("Existing moderation reason")
      end
    end

    context "when checking fingerprints for automatic suspension" do
      before { sign_in(user) }

      it "suspends matching accounts, records the action, and logs them out without hiding posts" do
        existing_post = Fabricate(:post, user: user)
        FlaggedFingerprint.create!(value: "abc", suspended: true)

        messages =
          MessageBus.track_publish("/logout/#{user.id}") do
            post "/fingerprint", params: fingerprint_params
          end

        expect(response.status).to eq(200)
        expect(user.reload).to be_suspended
        expect(user.suspended_till).to be > 100.years.from_now
        expect(user.suspend_record.acting_user_id).to eq(Discourse::SYSTEM_USER_ID)
        expect(user.suspend_reason).to be_blank
        expect(messages.map(&:data)).to eq([user.id])
        expect(existing_post.reload).not_to be_hidden

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(403)
        expect(user.user_histories.where(action: UserHistory.actions[:suspend_user]).count).to eq(1)
      end

      it "suspends accounts matching the fingerprint cookie" do
        SiteSetting.fingerprint_cookie = true
        cookies[:fp] = "shared-cookie"
        FlaggedFingerprint.create!(value: "shared-cookie", suspended: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).to be_suspended
        expect(Fingerprint.find_by!(user: user, value: "shared-cookie").name).to eq("cookie")
      end

      it "leaves unmatched accounts active" do
        FlaggedFingerprint.create!(value: "other", suspended: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_suspended
        expect(user.suspend_record).to be_nil
      end

      it "keeps hiding and silencing rules separate from suspension" do
        flagged = FlaggedFingerprint.create!(value: "abc", hidden: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_suspended
        expect(user).not_to be_silenced

        flagged.update!(silenced: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_suspended
        expect(user).to be_silenced
      end

      it "gives suspension precedence over a silencing rule on another matching hash" do
        SiteSetting.fingerprint_cookie = true
        cookies[:fp] = "shared-cookie"
        FlaggedFingerprint.create!(value: "abc", silenced: true)
        FlaggedFingerprint.create!(value: "shared-cookie", suspended: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).to be_suspended
        expect(user).not_to be_silenced
      end

      it "upgrades a silenced account without changing its existing silence" do
        UserSilencer.new(
          user,
          Discourse.system_user,
          reason: "Existing moderation reason",
          keep_posts: true,
        ).silence
        silence_id = user.silenced_record.id
        FlaggedFingerprint.create!(value: "abc", suspended: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).to be_suspended
        expect(user.silenced_record.id).to eq(silence_id)
        expect(user.silence_reason).to eq("Existing moderation reason")
      end

      it "leaves accounts active after the suspension rule is removed" do
        flagged = FlaggedFingerprint.create!(value: "abc", suspended: true)
        flagged.update!(suspended: false, hidden: true)

        post "/fingerprint", params: fingerprint_params

        expect(response.status).to eq(200)
        expect(user.reload).not_to be_suspended
      end
    end

    it "saves fingerprints for users" do
      expect {
        post "/fingerprint",
             params: {
               visitor_id: "abc",
               version: "1.0.0",
               data: { foo: "bar", audio: "baz" }.to_json,
             },
             headers: {
               "User-Agent" => "Discourse",
             }
      }.not_to change { Fingerprint.count }

      expect(response.status).to eq(403)

      sign_in(user)

      expect {
        post "/fingerprint",
             params: {
               visitor_id: "abc",
               version: "1.0.0",
               data: { foo: "bar", audio: "baz" }.to_json,
             },
             headers: {
               "User-Agent" => "Discourse",
             }
      }.to change { Fingerprint.count }.by(2)

      expect(response.status).to eq(200)

      expect {
        SiteSetting.fingerprint_cookie = true

        post "/fingerprint",
             params: {
               visitor_id: "abc",
               version: "1.0.0",
               data: { foo: "bar", audio: "baz" }.to_json,
             },
             headers: {
               "User-Agent" => "Discourse",
             }
      }.to change { Fingerprint.count }.by(1)

      expect(response.status).to eq(200)
      expect(response.headers["Set-Cookie"]).to start_with("fp=")

      expect {
        SiteSetting.fingerprint_ip = true

        post "/fingerprint",
             params: {
               visitor_id: "abc",
               version: "1.0.0",
               data: { foo: "bar", audio: "baz" }.to_json,
             },
             headers: {
               "User-Agent" => "Discourse",
             }
      }.to change { Fingerprint.count }.by(1)

      expect(response.status).to eq(200)
    end
  end
end
