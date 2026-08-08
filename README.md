# Growbox Controller – Home Assistant Blueprint

A comprehensive **Home Assistant automation blueprint** for controlling one or
more grow-boxes / grow-tents.

## Features

| Category | Capability |
|---|---|
| **Environment monitoring** | Temperature, humidity, VOC, CO₂, PM2.5 |
| **Soil & irrigation** | Soil-moisture measurement, automatic pump control |
| **Lighting** | Vegetative (18 h) and flowering (12 h) schedules |
| **Ventilation** | Fan auto-control based on temperature / humidity / CO₂ |
| **Air pressure** | Pressure monitoring, optional automatic fan optimisation |
| **Timelapse** | Periodic camera snapshots for time-lapse videos |
| **Phase tracking** | Elapsed days & weeks shown in persistent notifications |
| **Notifications** | Multi-level alerts (info / warning ⚠️ / critical 🚨) |
| **Multi-chamber** | Deploy one automation per chamber – fully independent |

---

## Requirements

- Home Assistant 2023.4 or newer
- The following integrations / entities already configured in HA:
  - Temperature sensor (`sensor` with `device_class: temperature`)
  - Humidity sensor (`sensor` with `device_class: humidity`)
  - VOC sensor (`sensor`)
  - CO₂ sensor (`sensor`)
  - PM2.5 sensor (`sensor`)
  - Soil moisture sensor (`sensor`)
  - Grow light (`switch` or `light`)
  - Fan (`switch`)
  - Water pump (`switch`)
  - *(Optional)* Air-pressure sensor (`sensor` with `device_class: pressure`)
  - *(Optional)* Camera (`camera`)

---

## Installation

### Option A – My Home Assistant (one-click)

[![Open your Home Assistant instance and show the blueprint import dialog with
a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fchristianschmidt123%2FGreenhouse-HA-Blueprint%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fgrowbox_controller.yaml)

### Option B – Manual

1. Copy `blueprints/automation/growbox_controller.yaml` into your Home
   Assistant config folder:

   ```
   config/blueprints/automation/growbox_controller.yaml
   ```

2. Restart Home Assistant (or reload automations).

3. Navigate to **Settings → Automations → Blueprints**, find
   *Growbox Controller* and click **Create automation**.

---

## Configuration

Every input has an in-app description. Key inputs:

### Chamber identification
- **Chamber name** – unique label shown in notifications (e.g. "Veg Tent",
  "Flower Box 1").

### Growth phase
| Phase | Light | Typical use |
|---|---|---|
| Vegetative | 18 h on / 6 h off | Clones, seedlings, veg growth |
| Flowering | 12 h on / 12 h off | Bloom induction (e.g. cannabis) |

Set **Phase start date** to record when the current phase began – the
blueprint then calculates and displays elapsed days and weeks automatically.

### Thresholds

Each monitored value has a **warning** and a **critical** threshold:

| Value | Warning action | Critical action |
|---|---|---|
| Temperature high | Fan on (if enabled), ⚠️ notify | Fan forced on, 🚨 notify |
| Temperature low | ⚠️ notify | – |
| Humidity high | Fan on (if enabled), ⚠️ notify | Fan forced on, 🚨 notify |
| Humidity low | ⚠️ notify | – |
| CO₂ high | Fan on (if enabled), ⚠️ notify | Fan forced on, 🚨 notify |
| VOC high | ⚠️ notify | Fan forced on, 🚨 notify |
| PM2.5 high | ⚠️ notify | Fan forced on, 🚨 notify |

### Irrigation
- Pump activates automatically when soil moisture drops below **Minimum soil
  moisture**.
- Pump runs for the configured **Pump run time** (seconds) and stops.
- A safety shut-off also triggers when moisture exceeds **Maximum soil
  moisture**.

### Timelapse
- Set the **Camera entity** and **Snapshot interval** (minutes).
- Snapshots are saved to **Snapshot output path** with filenames in the format
  `<chamber_slug>_YYYYMMDD_HHMMSS.jpg`.
- Leave the camera field empty to disable this feature.

### Notifications
- Set **Notification service** to any `notify.*` service in your HA instance.
- Examples: `notify.mobile_app_myphone`, `notify.persistent_notification`,
  `notify.telegram`.

---

## Multiple chambers

To control two or more chambers independently:

1. Create one automation from the blueprint per chamber.
2. Give each automation a different **Chamber name** (e.g. "Chamber 1",
   "Chamber 2").
3. Assign each automation its own set of sensor / switch entities.

Each automation runs fully independently – there is no shared state between
chambers.

---

## Default threshold values

| Sensor | Warning | Critical |
|---|---|---|
| Temperature max | 30 °C | 35 °C |
| Temperature min | 18 °C | – |
| Humidity max | 70 % | 85 % |
| Humidity min | 40 % | – |
| CO₂ max | 1 500 ppm | 2 000 ppm |
| VOC index max | 200 | 350 |
| PM2.5 max | 25 µg/m³ | 75 µg/m³ |
| Soil moisture min | 30 % | – |
| Soil moisture max | 70 % | – |

All defaults can be overridden per-chamber in the automation configuration.

---

## License

MIT – see [LICENSE](LICENSE).