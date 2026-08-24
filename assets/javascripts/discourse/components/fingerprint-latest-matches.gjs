import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { trustHTML } from "@ember/template";
import DButton from "discourse/components/d-button";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import icon from "discourse/helpers/d-icon";
import { and, not } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class FingerprintLatestMatches extends Component {
  @tracked hideCommon = true;

  <template>
    <div class="section">
      <div class="section-title">
        <h2>{{i18n "fingerprint.latest_matches"}}</h2>
      </div>
      <div class="section-body">
        {{trustHTML
          (i18n
            "fingerprint.latest_matches_instructions"
            algorithm="<a href='https://github.com/Valve/fingerprintjs2'>Fingeprintjs2</a>"
          )
        }}

        {{#if @fingerprints.length}}
          <table>
            <thead>
              <tr>
                <th></th>
                <th>{{i18n "fingerprint.results.hash"}}</th>
                <th>{{i18n "fingerprint.results.matches"}}</th>
                <th colspan="3">
                  <Input
                    @type="checkbox"
                    id="hide-common"
                    @checked={{this.hideCommon}}
                  />
                  <label for="hide-common">{{i18n
                      "fingerprint.hide_common"
                    }}</label>
                </th>
              </tr>
            </thead>
            <tbody>
              {{#each @fingerprints as |fingerprint|}}
                {{#if (not (and this.hideCommon fingerprint.is_common))}}
                  <tr>
                    <td>{{icon fingerprint.device_type}}</td>
                    <td>
                      <small>
                        {{fingerprint.name}}
                        {{#if fingerprint.is_common}}
                          <span
                            data-tooltip={{i18n "fingerprint.common_device"}}
                          >{{icon "layer-group"}}</span>
                        {{/if}}
                      </small>
                      <br />
                      {{fingerprint.value}}
                    </td>
                    <td>
                      <small>{{fingerprint.user_ids.length}}</small>
                      {{#each fingerprint.users as |u|}}
                        <UserLink @user={{u}}>
                          {{avatar u imageSize="small"}}
                        </UserLink>
                      {{/each}}
                    </td>
                    <td>
                      {{#if fingerprint.hidden}}
                        <DButton
                          @action={{fn @flag "hide" fingerprint "yes"}}
                          @icon="far-eye"
                          @label="js.fingerprint.unhide"
                          class="btn-flat"
                        />
                      {{else}}
                        <DButton
                          @action={{fn @flag "hide" fingerprint}}
                          @icon="far-eye-slash"
                          @label="js.fingerprint.hide"
                          class="btn-flat"
                        />
                      {{/if}}
                    </td>
                    <td>
                      {{#if fingerprint.silenced}}
                        <DButton
                          @action={{fn @flag "silence" fingerprint "yes"}}
                          @icon="microphone"
                          @label="js.fingerprint.unsilence"
                          class="btn-flat"
                        />
                      {{else}}
                        <DButton
                          @action={{fn @flag "silence" fingerprint}}
                          @icon="microphone-slash"
                          @label="js.fingerprint.silence"
                          class="btn-flat silence"
                        />
                      {{/if}}
                    </td>
                    <td>
                      {{#if fingerprint.data}}
                        <DButton
                          @action={{fn @showFingerprintData fingerprint.data}}
                          @icon="info"
                          @label="js.fingerprint.details"
                          class="btn-flat"
                        />
                      {{/if}}
                    </td>
                  </tr>
                {{/if}}
              {{/each}}
            </tbody>
          </table>
        {{else}}
          {{i18n "fingerprint.matches_not_found"}}
        {{/if}}
      </div>
    </div>
  </template>
}
