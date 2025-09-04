<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="space-y-5 sm:space-y-6">
      <ComponentCard title="Basic Table 1">
        <TabulatorE />
      </ComponentCard>
    </div>
  </AdminLayout>
</template>


<script setup>
import { ref } from "vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";
import AdminLayout from "@/components/layout/AdminLayout.vue";
import ComponentCard from "@/components/common/ComponentCard.vue";
import TabulatorE from "@/components/tables/TabulatorE.vue";
const currentPageTitle = ref("Basic Tables");




</script>
