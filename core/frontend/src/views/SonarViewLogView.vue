<template>
  <BrIframe
    :source="full_path"
  />
</template>

<script lang="ts">
import Vue from 'vue'

import BrIframe from '@/components/utils/BrIframe.vue'

/* SonarView writes its recordings under /usr/blueos/userdata/SonarView, one
   folder per session. Filebrowser reaches that through its /shortcuts/userdata
   symlink, so this is the same file browser served at /tools/file-browser,
   just opened at the recordings folder. The path's case must match the
   directory exactly - the extension binds "SonarView", not "sonarview". */
const SONARVIEW_LOG_PATH = 'files/userdata/SonarView'

export default Vue.extend({
  name: 'SonarViewLogView',
  components: {
    BrIframe,
  },
  data() {
    return {
      service_path: '/file-browser/',
    }
  },
  computed: {
    full_path() {
      return `${this.service_path}${SONARVIEW_LOG_PATH}`
    },
  },
})
</script>
