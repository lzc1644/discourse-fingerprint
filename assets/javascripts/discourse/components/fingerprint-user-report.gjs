import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import icon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

export default class FingerprintUserReport extends Component {
  get usersArray() {
    return Object.values(this.args.users || {});
  }

  <template>
    <div class="section">
      <div class="section-title">
        <h2>
          {{i18n "fingerprint.matches_for"}}
          <UserLink @user={{@user}}>
            {{avatar @user imageSize="medium"}}
            {{@user.username}}
          </UserLink>
        </h2>
      </div>
      <div class="section-body">
        {{#if this.usersArray.length}}
          <p>{{i18n
              "fingerprint.matches_found"
              count=this.usersArray.length
            }}</p>

          <table>
            <thead>
              <tr>
                <th>{{i18n "fingerprint.results.matching_user"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each this.usersArray as |user|}}
                <tr>
                  <td>
                    <UserLink @user={{user}}>
                      {{avatar user imageSize="small"}}
                      {{user.username}}
                    </UserLink>
                  </td>
                  <td>
                    {{#if user.ignored}}
                      <DButton
                        @action={{fn @ignore user "yes"}}
                        @icon="user"
                        @label="js.fingerprint.unignore"
                        class="btn-flat"
                      />
                    {{else}}
                      <DButton
                        @action={{fn @ignore user}}
                        @icon="user-slash"
                        @label="js.fingerprint.ignore"
                        class="btn-flat"
                      />
                    {{/if}}
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          {{i18n "fingerprint.matches_not_found"}}
        {{/if}}
      </div>
    </div>

    <div class="section">
      <div class="section-title">
        <h2>{{i18n "fingerprint.details"}}</h2>
      </div>
      <div class="section-body">
        {{#if @fingerprints.length}}
          <table>
            <thead>
              <tr>
                <th></th>
                <th>{{i18n "fingerprint.results.hash"}}</th>
                <th>{{i18n "fingerprint.results.first_seen"}}</th>
                <th>{{i18n "fingerprint.results.last_seen"}}</th>
                <th>{{i18n "fingerprint.results.matches"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @fingerprints as |fingerprint|}}
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
                  <td>{{formatDate fingerprint.created_at}}</td>
                  <td>{{formatDate fingerprint.updated_at}}</td>
                  <td>
                    <p>
                      {{#each fingerprint.users as |u|}}
                        {{#unless u.ignored}}
                          <UserLink @user={{u}}>
                            {{avatar u imageSize="small"}}
                          </UserLink>
                        {{/unless}}
                      {{/each}}
                    </p>
                  </td>
                  <td class="details-col">
                    {{#if fingerprint.hidden}}
                      <DButton
                        @action={{fn @flag "hide" fingerprint "yes"}}
                        @icon="far-eye"
                        @title="js.fingerprint.unhide"
                        class="btn-flat no-text"
                      />
                    {{else}}
                      <DButton
                        @action={{fn @flag "hide" fingerprint}}
                        @icon="far-eye-slash"
                        @title="js.fingerprint.hide"
                        class="btn-flat no-text"
                      />
                    {{/if}}
                    {{#if fingerprint.silenced}}
                      <DButton
                        @action={{fn @flag "silence" fingerprint "yes"}}
                        @icon="microphone"
                        @title="js.fingerprint.unsilence"
                        class="btn-flat no-text"
                      />
                    {{else}}
                      <DButton
                        @action={{fn @flag "silence" fingerprint}}
                        @icon="microphone-slash"
                        @title="js.fingerprint.silence"
                        class="btn-flat no-text silence"
                      />
                    {{/if}}
                    {{#if fingerprint.data}}
                      <DButton
                        @action={{fn @showFingerprintData fingerprint.data}}
                        @icon="info"
                        @title="js.fingerprint.details"
                        class="btn-flat no-text"
                      />
                    {{/if}}
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          {{i18n "fingerprint.none"}}
        {{/if}}
      </div>
    </div>
  </template>
}
