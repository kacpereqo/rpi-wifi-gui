
<template>
<div class="container">
  <div id="filters">
    <legend>Show</legend>
    <div v-for="prop in PROPERTIES">
      <input type="checkbox" :id="prop" :value="prop" v-model="selectedProperties">
      <label :for="prop" >{{ prop }}</label>
    </div>
  </div>
  <table>
    <thead>
      <tr>
        <th :colspan="selectedProperties.length">
          {{ apiUrl }}
        </th>
        <th>
          <button>options</button>
        </th>
      </tr>
            <tr>
        <th :colspan="selectedProperties.length + 1">
          <input type="text" id="searchBox" v-model="searchQuery" placeholder="Search by SSID...">
        </th>
      </tr>
    </thead>
    <tbody>
        <tr>
          <th v-for="prop in selectedProperties">
            {{ prop.toUpperCase() }}
          </th>
          <th>
            Action
          </th>
        </tr>
      <tr v-for="ap in apList?.filter(ap => ap.ssid.toLowerCase().includes(searchQuery) || !searchQuery.length)" :key="ap.bssid" :class="{connectedToAp: (ap['in_use'])}">
        <td v-for="prop in selectedProperties" :key="prop">
          {{ ap[prop] }}
        </td>
        <td>
          <button class="actionButton">{{ ap['in_use'] ? "Disconnect" : "Connect" }}</button>
        </td>
      </tr>
    </tbody>
  </table>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';

const searchQuery = ref()
const apiUrl = ref("http://127.0.0.1:8000")
const PROPERTIES: (keyof AccessPoint)[] = ["ssid", "bssid", "chan", "freq", "rate", "signal", "bandwidth", "bars", "security","active", "in_use"]
const selectedProperties =  ref(['ssid', 'bssid', 'freq', 'bars'])

interface AccessPoint {
  ssid: string
  bssid: string
  chan: string
  freq: string
  rate: string
  bandwidth: number
  signal: number
  bars: string
  security: string
  active: string
  in_use: boolean
}

const apList = ref<AccessPoint[]>()

async function connectToAccessPoint(accessPoint: AccessPoint, password?: string){
    const apConnectEndpoint = `${apiUrl.value}/ap/connect`

    const ssid = accessPoint.ssid
    const bssid = accessPoint.bssid

    const payload = {
      ssid,
      bssid,
      password
    }

    await fetch(apConnectEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
  }

async function fetchAccessPoints(){
  const apListEndpoint = `${apiUrl.value}/ap`
    await fetch(apListEndpoint).then(r=>
    {
    if (!r.ok)
      throw new Error(`${r.status}`)

    return r.json()
  }).then(r => {
    apList.value = r.access_points
    fetchAccessPoints()
  })
}

onMounted(async () => {
  await fetchAccessPoints()
})

</script>
<style scoped>
.container{
  display: flex;
  flex-direction: column;
  width: 60%;
}
table {
  width: 100%;        /* Ensures table fills its container */
  border-collapse: collapse;
  border: 2px solid rgb(140 140 140);
  font-family: sans-serif;
  font-size: 0.8rem;
  letter-spacing: 1px;
}

thead,
tfoot {
  background-color: rgb(228 240 245);
}

th,
td {
  border: 1px solid rgb(160 160 160);
  padding: 8px 10px;
}

td:last-of-type {
  text-align: center;
}

tbody > tr:nth-of-type(even) {
  background-color: rgb(237 238 242);
}

tfoot th {
  text-align: right;
}

tfoot td {
  font-weight: bold;
}
.connectedToAp{
  background-color: greenyellow !important;
}

#filters{
  display:flex;
  flex-direction: row;
  flex-wrap: wrap;
}

.actionButton{
  width: 100%;
  height: 100%;
}

#searchBox{
  width: 90%;
}
</style>
