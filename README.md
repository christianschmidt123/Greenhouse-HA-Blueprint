# Growbox Controller – Home Assistant Blueprint

A comprehensive **Home Assistant automation blueprint** for controlling one or
more grow-boxes / grow-tents.

---

## Features

| Category | Capability |
|---|---|
| **Environment monitoring** | Temperature, humidity (RLF), VOC, CO₂, PM2.5 |
| **Soil & irrigation** | Soil-moisture measurement, automatic pump control |
| **Lighting** | Vegetative (18 h) and flowering (12 h) schedules |
| **Circulation fan** | Auto-control based on temperature / humidity / CO₂ |
| **Exhaust fan (Abluft)** | Dedicated RLF-based hysteresis control; always-on during lights option |
| **Air pressure** | Pressure monitoring, optional auto-fan optimisation |
| **Timelapse** | Periodic camera snapshots; one-click MP4 video compilation |
| **Phase tracking** | Elapsed days & weeks in persistent notifications |
| **Repotting heuristic** | Notifies when soil-moisture drain rate spikes (root-bound indicator) |
| **Plant height tracking** | Sensor or input_number integration; growth-stall notification |
| **Nutrient deficiency** | REST-hook placeholder for external ML/CV analysis service |
| **Notifications** | Multi-level alerts: info / ⚠️ warning / 🚨 critical |
| **Dashboard** | Ready-to-import Lovelace YAML with timelapse video player & compile button |
| **Multi-chamber** | Deploy one automation per chamber – fully independent |

---

## Repository structure

```
blueprints/
  automation/
    growbox_controller.yaml        ← Main automation blueprint
  script/
    growbox_compile_timelapse.yaml ← Script blueprint: compile timelapse MP4
configuration/
  shell_commands.yaml              ← HA shell_command definitions (include in configuration.yaml)
  rest_commands.yaml               ← HA rest_command definitions (include in configuration.yaml)
scripts/
  compile_timelapse.sh             ← ffmpeg wrapper script
dashboards/
  growbox_dashboard.yaml           ← Example Lovelace dashboard
```

---

## Requirements

- Home Assistant 2023.4 or newer
- ffmpeg (pre-installed in HA OS; for Docker add to container image)
- The following entities already configured in HA:

| Entity type | Purpose |
|---|---|
| `sensor` (temperature) | Air temperature |
| `sensor` (humidity) | Relative air humidity (RLF) |
| `sensor` | VOC |
| `sensor` | CO₂ |
| `sensor` | PM2.5 |
| `sensor` | Soil moisture |
| `switch` or `light` | Grow light |
| `switch` | Circulation fan |
| `switch` | **Exhaust fan (Abluft)** |
| `switch` | Water pump |
| `sensor` or `input_number` | *(optional)* Plant height |
| `sensor` (pressure) | *(optional)* Air pressure |
| `camera` | *(optional)* Timelapse camera |

---

## Installation

### Step 1 – Copy blueprints

Copy the blueprint files to your HA config folder:

```
config/
  blueprints/
    automation/
      growbox_controller.yaml
    script/
      growbox_compile_timelapse.yaml
  scripts/
    compile_timelapse.sh      ← must be executable (chmod +x)
```

Or click the one-click import button:

[![Import blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fchristianschmidt123%2FGreenhouse-HA-Blueprint%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fgrowbox_controller.yaml)

### Step 2 – Add shell_command and rest_command to configuration.yaml

```yaml
# configuration.yaml
shell_command: !include blueprints/configuration/shell_commands.yaml
rest_command:  !include blueprints/configuration/rest_commands.yaml
```

Restart Home Assistant after editing `configuration.yaml`.

### Step 3 – Create timelapse snapshot directories

```bash
mkdir -p /config/www/timelapse/chamber1
```

### Step 4 – Create an automation from the blueprint

**Settings → Automations → Blueprints → Growbox Controller → Create automation**

Repeat for each additional chamber with its own entity set.

### Step 5 – Create a compile-timelapse script

**Settings → Automations → Blueprints → Growbox – Compile Timelapse Video →
Create script**

Point it to the same `snapshot_path` you used in the automation.

### Step 6 – Import the dashboard (optional)

1. **Settings → Dashboards → Add dashboard** → give it a name.
2. Open the dashboard → ⋮ menu → **Edit dashboard → Raw configuration editor**.
3. Paste the contents of `dashboards/growbox_dashboard.yaml`.
4. Replace all placeholder entity IDs (`sensor.xxx`, `switch.xxx`, …) with
   your real entity IDs.

---

## Exhaust fan (Abluft) – RLF-based control

The exhaust fan has its own independent RLF-based control loop with hysteresis
to prevent rapid on/off cycling:

| Input | Default | Description |
|---|---|---|
| `exhaust_humidity_on` | 65 % | Fan activates when humidity exceeds this value |
| `exhaust_humidity_off` | 55 % | Fan deactivates when humidity drops below this value |
| `exhaust_always_on_during_lights` | false | Forces exhaust on whenever the light is on (odour control) |

The exhaust fan is also activated by warning/critical thresholds for
temperature, humidity, CO₂, VOC and PM2.5.

---

## Timelapse video compilation

Snapshots are taken automatically every `snapshot_interval_minutes`.
To compile them into an MP4:

1. Open the dashboard and click **🎬 Compile Timelapse**.
2. Or call the script service from **Developer Tools → Services**.
3. When done, a persistent notification appears with the video path.
4. The video is served at `/local/timelapse/<filename>.mp4` and embedded
   directly in the dashboard.

The compilation uses ffmpeg with H.264 encoding for maximum browser
compatibility.

---

## Repotting heuristic

Every morning at 08:00 the blueprint logs the current soil moisture value and
notifies if the drain rate threshold is set. To get a quantitative drain-rate
measurement, create a `statistics` sensor in HA:

```yaml
# configuration.yaml
sensor:
  - platform: statistics
    name: "Soil moisture drain rate chamber1"
    entity_id: sensor.growbox_chamber1_soil_moisture
    state_characteristic: change_sample
    sampling_size: 12       # last 12 samples (= 1 h at 5-min polling)
    max_age:
      hours: 1
```

If this sensor reports a value below `-<threshold>`, the blueprint can be
extended with a trigger on it.

---

## Plant height tracking

**Option A – Manual (input_number helper)**

```yaml
# helpers / input_number section in configuration.yaml or UI
input_number:
  growbox_chamber1_plant_height:
    name: Chamber 1 plant height
    min: 0
    max: 300
    step: 0.5
    unit_of_measurement: cm
    icon: mdi:ruler
```

Update the value manually from the dashboard.

**Option B – Automatic (ultrasonic sensor via ESPHome)**

Wire an HC-SR04 (or JSN-SR04T) sensor to an ESP32/ESP8266 and expose it as a
`sensor` entity. The blueprint will use it directly.

---

## Nutrient deficiency detection

The blueprint can POST the latest snapshot to any REST endpoint for analysis.
Set `nutrient_webhook_url` to your service URL.

Example open-source services you can self-host:

- **PlantCV** – Python library for plant image analysis
  (https://plantcv.readthedocs.io/)
- **Custom Flask wrapper** around a PyTorch / TFLite classification model
  trained on labelled deficiency images

The endpoint must accept:
```json
POST /analyse
{ "snapshot": "/config/www/timelapse/chamber1/latest.jpg",
  "chamber": "Chamber 1" }
```
and return:
```json
{ "deficiency": "nitrogen", "confidence": 0.82 }
```

---

## Multiple chambers

Deploy one automation **and** one compile-timelapse script per chamber:

| Chamber | Automation | Snapshot path | Script |
|---|---|---|---|
| Chamber 1 | Growbox – Chamber 1 | `/config/www/timelapse/chamber1/` | Timelapse – Chamber 1 |
| Chamber 2 | Growbox – Chamber 2 | `/config/www/timelapse/chamber2/` | Timelapse – Chamber 2 |

Each automation is completely independent.

---

## Default threshold values

| Sensor | Warning | Critical |
|---|---|---|
| Temperature max | 30 °C | 35 °C |
| Temperature min | 18 °C | – |
| Humidity max | 70 % | 85 % |
| Humidity min | 40 % | – |
| Exhaust fan ON | 65 % | – |
| Exhaust fan OFF | 55 % | – |
| CO₂ max | 1 500 ppm | 2 000 ppm |
| VOC index max | 200 | 350 |
| PM2.5 max | 25 µg/m³ | 75 µg/m³ |
| Soil moisture min | 30 % | – |
| Soil moisture max | 70 % | – |

All defaults can be overridden per-chamber in the automation configuration.

---

## Recommended improvements from similar projects

Based on analysis of comparable open-source grow-controller projects
(Growduino, OpenGrow, various HA community threads):

1. **VPD (Vapour Pressure Deficit) calculation** – more accurate than raw
   humidity for plant stress. Add a template sensor:
   `VPD = 0.6108 * exp(17.27 * T / (T + 237.3)) * (1 - RH/100)`

2. **Day/night temperature differential** – lower temp by 2–4 °C during dark
   phase to mimic natural conditions and improve terpene/resin production.

3. **EC (Electrical Conductivity) / TDS sensor** for hydroponic nutrient
   monitoring via an analog sensor exposed through ESPHome.

4. **pH monitoring** for hydroponic / automated feeding systems.

5. **DLI (Daily Light Integral)** tracking – accumulate lux readings over the
   day to ensure plants receive optimal mol/m²/day.

6. **Automated flush reminder** – notify after N weeks in flowering to schedule
   a nutrient flush before harvest.

---

## License

MIT – see [LICENSE](LICENSE).
