import * as React from 'react';
import { Tab, TabGroup, TabList, TabPanel, TabPanels } from '@headlessui/react'

export default function TabTest({ tab1, tab2, content1, content2 }) {
  return (
    <TabGroup>
      <TabList>
        <Tab>{tab1}</Tab>
        <Tab>{tab2}</Tab>
      </TabList>
      <TabPanels>
        <TabPanel>{content1}</TabPanel>
        <TabPanel>{content2}</TabPanel>
      </TabPanels>
    </TabGroup>
  )
}
