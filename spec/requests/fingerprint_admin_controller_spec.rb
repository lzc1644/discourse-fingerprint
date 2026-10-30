# frozen_string_literal: true

RSpec.describe DiscourseFingerprint::FingerprintAdminController do
  fab!(:admin)
  fab!(:user)

  describe "#flag" do
    it "requires an administrator" do
      put "/admin/plugins/fingerprint/flag.json", params: { type: "suspend", value: "abc" }
      expect(response.status).to eq(403)

      sign_in(user)
      put "/admin/plugins/fingerprint/flag.json", params: { type: "suspend", value: "abc" }
      expect(response.status).to eq(403)
      expect(FlaggedFingerprint.find_by(value: "abc")).to be_nil
    end

    context "as an administrator" do
      before { sign_in(admin) }

      it "adds and removes a suspension rule without immediately suspending matching accounts" do
        Fingerprint.create!(user: user, name: "cookie", value: "shared-cookie")

        put "/admin/plugins/fingerprint/flag.json",
            params: {
              type: "suspend",
              value: "shared-cookie",
            }

        expect(response.status).to eq(200)
        expect(FlaggedFingerprint.find_by!(value: "shared-cookie")).to be_suspended
        expect(user.reload).not_to be_suspended

        user.update!(suspended_at: Time.current, suspended_till: 1.year.from_now)

        put "/admin/plugins/fingerprint/flag.json",
            params: {
              type: "suspend",
              value: "shared-cookie",
              remove: "yes",
            }

        expect(response.status).to eq(200)
        expect(FlaggedFingerprint.find_by(value: "shared-cookie")).to be_nil
        expect(user.reload).to be_suspended
      end

      it "preserves suspension when removing other flags and preserves other flags when removing it" do
        flagged =
          FlaggedFingerprint.create!(value: "abc", hidden: true, silenced: true, suspended: true)

        %w[hide silence].each do |type|
          put "/admin/plugins/fingerprint/flag.json",
              params: {
                type: type,
                value: "abc",
                remove: "yes",
              }
          expect(response.status).to eq(200)
        end

        expect(flagged.reload).to have_attributes(hidden: false, silenced: false, suspended: true)

        flagged.update!(hidden: true, silenced: true)
        put "/admin/plugins/fingerprint/flag.json",
            params: {
              type: "suspend",
              value: "abc",
              remove: "yes",
            }

        expect(response.status).to eq(200)
        expect(flagged.reload).to have_attributes(hidden: true, silenced: true, suspended: false)
      end

      it "rejects an invalid rule type or an empty fingerprint" do
        put "/admin/plugins/fingerprint/flag.json", params: { type: "unknown", value: "abc" }
        expect(response.status).to eq(400)

        put "/admin/plugins/fingerprint/flag.json", params: { type: "suspend", value: "" }
        expect(response.status).to eq(400)
        expect(FlaggedFingerprint.count).to eq(0)
      end
    end
  end

  describe "#index" do
    before { sign_in(admin) }

    it "includes suspension rules in the flagged report" do
      Fingerprint.create!(user: user, name: "cookie", value: "shared-cookie")
      FlaggedFingerprint.create!(value: "shared-cookie", suspended: true)

      get "/admin/plugins/fingerprint/report.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["flagged"].sole).to include(
        "name" => "cookie",
        "value" => "shared-cookie",
        "suspended" => true,
        "silenced" => false,
        "count" => 1,
      )
    end
  end

  describe "#user_report" do
    before { sign_in(admin) }

    it "includes the current rule state in individual reports after a reload" do
      Fingerprint.create!(user: user, name: "cookie", value: "shared-cookie")
      flagged = FlaggedFingerprint.create!(value: "shared-cookie", silenced: true, suspended: true)

      get "/admin/plugins/fingerprint/user_report.json", params: { username: user.username }

      expect(response.status).to eq(200)
      expect(response.parsed_body["fingerprints"].sole).to include(
        "value" => "shared-cookie",
        "silenced" => true,
        "suspended" => true,
      )

      flagged.update!(suspended: false)
      get "/admin/plugins/fingerprint/user_report.json", params: { username: user.username }

      expect(response.status).to eq(200)
      expect(response.parsed_body["fingerprints"].sole).to include(
        "silenced" => true,
        "suspended" => false,
      )
    end
  end
end
