# frozen_string_literal: true

describe DiscourseFingerprint::FingerprintController do
  let(:user) { Fabricate(:user) }

  describe "#index" do
    context "when checking fingerprints for automatic silencing" do
      let(:fingerprint_params) do
        { visitor_id: "abc", version: "1.0.0", data: { foo: "bar", audio: "baz" }.to_json }
      end

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
