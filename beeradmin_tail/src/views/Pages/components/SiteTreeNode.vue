<template>
  <div>
    <button
      type="button"
      class="w-full text-left px-2 py-1 rounded text-sm flex items-center gap-2"
      :class="selectedId === node.id ? 'bg-blue-50 text-blue-700' : 'text-gray-700 hover:bg-gray-50'"
      @click="$emit('select', node)"
    >
      <span v-if="hasChildren" class="text-gray-500" @click.stop="toggle">
        <svg v-if="expanded" width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M7 10l5 5 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M10 7l5 5-5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </span>
      <span v-if="hasChildren" class="text-amber-500">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
          <path d="M10 4l2 2h6a2 2 0 012 2v8a3 3 0 01-3 3H7a3 3 0 01-3-3V6a2 2 0 012-2h4z"/>
        </svg>
      </span>
      <span>{{ node.name }}</span>
      <span
        class="ml-1 px-1.5 py-0.5 rounded text-[10px] font-medium border"
        :class="node.owner_type === 'OUTSIDE'
          ? 'bg-amber-50 text-amber-700 border-amber-200'
          : 'bg-blue-50 text-blue-700 border-blue-200'"
      >
        {{ node.owner_type === 'OUTSIDE' ? t('site.ownerType.outsideShort') : t('site.ownerType.ownShort') }}
      </span>
    </button>
    <ul v-if="hasChildren && expanded" class="ml-3 mt-1 space-y-1">
      <li v-for="child in node.children" :key="child.id">
        <SiteTreeNode :node="child" :selected-id="selectedId" @select="$emit('select', $event)" />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'

interface TreeNode {
  id: string
  name: string
  owner_type: string
  site_type_id: string
  parent_site_id: string | null
  row: any
  children: TreeNode[]
}

defineEmits<{ (e: 'select', node: TreeNode): void }>()

const props = defineProps<{ node: TreeNode; selectedId: string | null }>()
const { t } = useI18n()

const expanded = ref(true)
const hasChildren = computed(() => Array.isArray(props.node.children) && props.node.children.length > 0)

function toggle() {
  if (!hasChildren.value) return
  expanded.value = !expanded.value
}
</script>
