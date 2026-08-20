<template>
  <v-container>
    <v-card
      v-if="logs_fetched"
      elevation="1"
    >
      <v-card-title class="ma-4">
        SonarView Logs
        <v-spacer />
        <v-btn
          v-tooltip="'Fetch available logs'"
          icon
          @click="fetchAvailableLogs"
        >
          <v-icon>mdi-update</v-icon>
        </v-btn>
        <v-btn
          v-tooltip="'Download selected logs'"
          icon
          color="success"
          :disabled="disable_batch_operations"
          @click="downloadSelectedLogs"
        >
          <v-icon>mdi-download-multiple</v-icon>
        </v-btn>
        <v-btn
          v-tooltip="'Delete selected logs'"
          icon
          color="error"
          :disabled="disable_batch_operations"
          @click="removeLogs"
        >
          <v-icon>mdi-trash-can</v-icon>
        </v-btn>
      </v-card-title>
      <v-card-text>
        <v-data-table
          v-model="selected_logs"
          :headers="headers"
          :items="parsed_logs"
          item-key="path"
          show-select
          :sort-by.sync="sortBy"
          :sort-desc.sync="sortDesc"
        >
          <template #item.size="{ item }">
            {{ printSize(item.size) }}
          </template>
          <template #item.actions="{ item }">
            <v-btn
              v-tooltip="'Download log'"
              icon
              @click="downloadLogs([item])"
            >
              <v-icon>mdi-download</v-icon>
            </v-btn>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
    <v-container v-else>
      <spinning-logo
        size="30%"
        subtitle="Fetching SonarView logs..."
      />
    </v-container>
  </v-container>
</template>

<script lang="ts">
import { format } from 'date-fns'
import Vue from 'vue'

import filebrowser from '@/libs/filebrowser'
import { FilebrowserFile } from '@/types/filebrowser'
import { prettifySize } from '@/utils/helper_functions'

import SpinningLogo from '../common/SpinningLogo.vue'

/* Root that SonarView writes its recordings under. Must match the directory's
   real case: the extension binds /usr/blueos/userdata/SonarView, and filebrowser
   reaches it through the /shortcuts/userdata symlink, so a lowercase path simply
   does not exist. */
const SONARVIEW_LOG_ROOT = '/userdata/SonarView'

/* A recording lives at <root>/<session>/<file>, so its session is the name of
   the folder holding it. Anything found directly in the root has no session
   folder, and gets a dash rather than an invented name. */
function sessionFromPath(path: string): string {
  const relative = path.startsWith(`${SONARVIEW_LOG_ROOT}/`)
    ? path.slice(SONARVIEW_LOG_ROOT.length + 1)
    : path
  const segments = relative.split('/')
  return segments.length > 1 ? segments[0] : '—'
}

/* A recording plus the session folder it came from. */
type SonarViewLog = FilebrowserFile & { session: string }

export default Vue.extend({
  name: 'SonarViewLogManager',
  components: {
    SpinningLogo,
  },
  data() {
    return {
      sortBy: 'modified',
      sortDesc: true,
      available_logs: [] as FilebrowserFile[],
      logs_fetched: false,
      selected_logs: [] as FilebrowserFile[],
      headers: [
        {
          text: 'Session',
          align: 'start',
          value: 'session',
        },
        {
          text: 'Name',
          align: 'start',
          sortable: false,
          value: 'name',
        },
        { text: 'Size', value: 'size' },
        { text: 'Type', value: 'extension' },
        { text: 'Modified', value: 'modified' },
        {
          text: 'Actions',
          align: 'end',
          sortable: false,
          value: 'actions',
        },
      ],
    }
  },
  computed: {
    disable_batch_operations(): boolean {
      return this.selected_logs.isEmpty()
    },
    parsed_logs(): SonarViewLog[] {
      return this.available_logs.map((log) => ({
        ...log,
        session: sessionFromPath(log.path),
        modified: format(new Date(log.modified), 'yyyy-MM-dd HH:mm:ss'),
      }))
    },
  },
  async mounted() {
    await this.fetchAvailableLogs()
  },
  methods: {
    async fetchAvailableLogs(): Promise<void> {
      const new_logs: FilebrowserFile[] = []

      const log_folders = [SONARVIEW_LOG_ROOT]

      // We fetch all paths in parallel and wait for everything to finish
      // If it fails the folder does not exist, we display a 'No data available' message
      // If it succeeds, it'll populate the array and show the logs to the user
      try {
        // Use allSettled to allow promises to fail in parallel
        await Promise.allSettled(log_folders.map(async (folder_path) => {
          const folder = await filebrowser.fetchFolder(folder_path)
          Array.prototype.push.apply(new_logs, folder.items)

          // SonarView writes each recording into a folder named after the
          // session that produced it, so the logs sit one level below the root
          // rather than in it. Descend into those folders as well. Items carry
          // their own absolute path, so downloads still resolve correctly.
          await Promise.allSettled(folder.items.filter((item) => item.isDir).map(async (session) => {
            const session_folder = await filebrowser.fetchFolder(session.path)
            Array.prototype.push.apply(new_logs, session_folder.items)
          }))
        }))
      } catch (_) {
        // We are going to ignore the error as described on the first comment and
        // continue with the following lines
      }

      this.logs_fetched = true
      // Filter for SonarView recordings only. They are written as .svlz;
      // .svlog is kept as well so anything older still shows up. This also
      // discards the directory entries picked up above, and the config.json /
      // errlog.jsonl files that live alongside the session folders.
      const log_extensions = ['.svlz', '.svlog']
      this.available_logs = new_logs.filter(
        (log) => {
          const ext = log.extension.toLowerCase()
          return log_extensions.includes(ext) && log.size > 0
        },
      )
    },
    downloadSelectedLogs(): void {
      this.downloadLogs(this.selected_logs)
      this.selected_logs = []
    },
    downloadLogs(logs: FilebrowserFile[]): void {
      filebrowser.downloadFiles(logs)
    },
    printSize(size_bytes: number): string {
      return prettifySize(size_bytes / 1024)
    },
    async removeLogs(): Promise<void> {
      if (this.selected_logs.isEmpty()) return

      await filebrowser.deleteFiles(this.selected_logs)

      await this.fetchAvailableLogs()
      this.selected_logs = []
    },
  },
})
</script>
