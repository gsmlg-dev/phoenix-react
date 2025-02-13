import * as React from 'react';
import { useSyncExternalStore } from 'react';
import { hydrateRoot } from 'react-dom/client';

import { Component as LiveForm } from '../component/live_form';

const LiveFormHook = {
  LiveFormHook: {
    mounted() {
      const formState = new FormState();

      formState.setData = (data) => {
        this.pushEvent("form:input", data);
      };

      function LiveViewForm(props) {
        const data = useSyncExternalStore(formState.subscribe, formState.getSnapshot, formState.getServerSnapshot);
        return <LiveForm data={data} setData={formState.setData} />;
      }

      this.pushEvent("form:init", {}, (reply, ref) => {
        formState.reset(reply);
        console.log("form:init", reply);
        this.reactRoot = hydrateRoot(this.el, <LiveViewForm />);
      });
      this.handleEvent("form:update", (data) => {
        console.log("form:update", data);
        formState.assign(data);
      });
    },
    destroyed() {
      this.reactRoot?.unmount();
    },
  }
}

const hooks = {
  ...LiveFormHook,
};

export { hooks };

class FormState {
  constructor() {
    this.subscribers = [];
    this.data = {};
    this.subscribe = this.subscribe.bind(this);
    this.getSnapshot = this.getSnapshot.bind(this);
    this.getServerSnapshot = this.getServerSnapshot.bind(this);
  }

  assign(data) {
    this.data = {
      ...this.data,
      ...data,
    };
    console.log('assign', data);
    this.subscribers.forEach(cb => {
      console.log('assign cb', cb, this.data);
      cb(this.data);
    });
  }

  reset(data) {
    this.data = data;
    this.subscribers.forEach(cb => cb(data));
  }

  getSnapshot() {
    return this.data;
  }

  subscribe(callback) {
    this.subscribers.push(callback);
    return () => {
      this.subscribers = this.subscribers.filter(s => s !== callback);
    };
  }

  getServerSnapshot() {
    return this.data;
  }
}
