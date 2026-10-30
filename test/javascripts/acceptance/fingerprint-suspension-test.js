import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { parsePostData } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Fingerprint suspension rules", function (needs) {
  needs.user({ admin: true });
  needs.settings({ fingerprint_enabled: true });

  let suspended;
  let changes;

  const user = {
    id: 101,
    username: "matched",
    avatar_template: "/letter_avatar_proxy/v4/letter/m/0088cc/{size}.png",
  };

  function fingerprint() {
    return {
      name: "cookie",
      value: "shared-cookie",
      user_ids: [user.id],
      count: 1,
      hidden: false,
      silenced: false,
      suspended,
    };
  }

  needs.hooks.beforeEach(() => {
    suspended = false;
    changes = 0;
  });

  needs.pretender((server, helper) => {
    server.post("/fingerprint", () => helper.response({ success: true }));

    server.get("/admin/plugins/fingerprint/report", () =>
      helper.response({
        fingerprints: suspended ? [] : [fingerprint()],
        flagged: suspended ? [fingerprint()] : [],
        users: { [user.id]: user },
      })
    );

    server.get("/admin/plugins/fingerprint/user_report", () =>
      helper.response({
        user,
        fingerprints: [fingerprint()],
        users: {},
        ignored_ids: [],
      })
    );

    server.put("/admin/plugins/fingerprint/flag", (request) => {
      const data = parsePostData(request.requestBody);
      suspended = !data.remove;
      changes++;
      return helper.response({ success: true });
    });
  });

  test("an administrator confirms a suspension rule and can remove it from flagged fingerprints", async function (assert) {
    await visit("/admin/plugins/fingerprint");
    await click(".dashboard-fingerprint .suspend");

    assert.dom(".dialog-body").includesText("suspended indefinitely");
    await click(".dialog-footer .btn-default");
    assert.strictEqual(changes, 0, "cancel leaves the rule unchanged");

    await click(".dashboard-fingerprint .suspend");
    await click(".dialog-footer .btn-danger");

    assert.strictEqual(changes, 1, "confirmation saves the rule");
    assert.dom(".dashboard-fingerprint .d-icon-unlock").exists();
    assert.dom(".dashboard-fingerprint").includesText("Remove suspension rule");

    await click(".dashboard-fingerprint .d-icon-unlock");

    assert.strictEqual(changes, 2, "removing the rule saves the change");
    assert.dom(".dashboard-fingerprint .suspend").exists();
  });

  test("an administrator sees the saved suspension state in an individual user report", async function (assert) {
    await visit("/admin/plugins/fingerprint?username=matched");
    await click(".dashboard-fingerprint .suspend");
    await click(".dialog-footer .btn-danger");

    assert
      .dom('.dashboard-fingerprint button[title="Remove suspension rule"]')
      .exists("the refreshed user report reflects the saved rule");

    await visit("/admin/plugins/fingerprint");
    await visit("/admin/plugins/fingerprint?username=matched");

    assert
      .dom('.dashboard-fingerprint button[title="Remove suspension rule"]')
      .exists("the saved state survives leaving and returning");

    await click(
      '.dashboard-fingerprint button[title="Remove suspension rule"]'
    );
    assert.dom(".dashboard-fingerprint .suspend").exists();
  });
});
