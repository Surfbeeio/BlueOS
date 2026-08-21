<template>
  <BrIframe
    :source="service_path"
  />
</template>

<script lang="ts">
import Vue from 'vue'

import BrIframe from '@/components/utils/BrIframe.vue'

export default Vue.extend({
  name: 'SonarViewLogView',
  components: {
    BrIframe,
  },
  data() {
    return {
      /* A second filebrowser instance, rooted at SonarView's recordings folder
         rather than at /shortcuts. That folder is therefore its home directory:
         the breadcrumb starts there and there is nothing above it to navigate
         up into. It also carries its own rule hiding the config and error-log
         files, so only the per-session folders and their .svlz recordings show.

         This needs a separate instance because filebrowser's root and rules
         belong to the instance, not to a URL - pointing the shared instance at
         this folder would have re-rooted the main File Browser page too. See
         core/tools/filebrowser/bootstrap.sh and core/start-blueos-core. */
      service_path: '/sonarview-browser/',
    }
  },
})
</script>
