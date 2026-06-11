<template>
  <SonarViewLogManager />
</template>

<script lang="ts">
import Vue from 'vue'

import SonarViewLogManager from '@/components/logs/SonarViewLogManager.vue'

export default Vue.extend({
  name: 'SonarViewLogView',
  components: {
    SonarViewLogManager,
  },
})
</script>
