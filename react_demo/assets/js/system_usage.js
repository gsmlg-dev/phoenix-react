import * as React from 'react';
import { useSyncExternalStore } from 'react';
import { hydrateRoot } from 'react-dom/client';

import { Component as SystemUsage } from "../component/system_usage";

import socket from "./server_socket";


document.addEventListener('DOMContentLoaded', function() {
  const store = new Store();
  const domContainer = document.querySelector('#system_usage_container');
  if (domContainer) {
    let channel = socket.channel("system_usage:lobby", {});

    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) });


    function Usage(props) {
      const data = useSyncExternalStore(store.subscribe, store.getSnapshot, store.getServerSnapshot);

      return <SystemUsage data={data} />;
    }

    let root;

    channel.on("joined", (data) => {
      // console.log("Reset stats: ", data)
      store.reset(data.data)

      requestAnimationFrame(() => {
        hydrateRoot(domContainer, <Usage />);
      });
    });

    channel.on("stats", (data) => {
      // console.log("Stats: ", data)
      store.unshift(data)
    });

  }
});

class Store {
  subscribers = [];
  data = [];

  constructor() {
    this.subscribe = this.subscribe.bind(this);
    this.getSnapshot = this.getSnapshot.bind(this);
    this.getServerSnapshot = this.getServerSnapshot.bind(this);
  }

  unshift(data) {
    this.data.unshift(data);
    this.data = this.data.slice(0, 100);
    this.subscribers.forEach(cb => cb(this.data));
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
