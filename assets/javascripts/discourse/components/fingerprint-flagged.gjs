import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { trustHTML } from "@ember/template";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class FingerprintFlagged extends Component {
  <template>
    <div class="section">
      <div class="section-title">
        <h2>{{i18n "fingerprint.flagged"}}</h2>
      </div>
      <div class="section-body">
        {{trustHTML (i18n "fingerprint.flagged_instructions")}}

        {{#if @flagged.length}}
          <table>
            <thead>
              <tr>
                <th>{{i18n "fingerprint.results.hash"}}</th>
                <th>{{i18n "fingerprint.results.matches"}}</th>
                <th></th>
                <th></th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @flagged as |fingerprint|}}
                <tr>
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
                  <td>{{fingerprint.count}}</td>
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
              {{/each}}
            </tbody>
          </table>
        {{else}}
          {{i18n "fingerprint.flagged_not_found"}}
        {{/if}}
      </div>
    </div>
  </template>
}
