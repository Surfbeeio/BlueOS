<template>
  <BrIframe
    :source="full_path"
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
      service_path: '/file-browser/#/files/userdata/sonarview',
    }
  },
  computed: {
    full_path(): string {
      return this.service_path
    },
  },
})
</script>
