import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["jar", "fill"]
  static values = {
    currentValue: Number,
    maxValue: Number,
    seasonYear: Number
  }

  connect() {
    this.render()
    this.applySplashIfLargeJump()
    this.bindTilt()
  }

  disconnect() {
    if (this.orientationHandler) {
      window.removeEventListener("deviceorientation", this.orientationHandler)
    }
  }

  render() {
    const current = Number(this.currentValueValue || 0)
    const max = Math.max(Number(this.maxValueValue || 0), 1)
    const percent = (current / max) * 100
    const fillPercent = Math.max(0, Math.min(percent, 100))
    const overflowPercent = Math.max(0, percent - 100)

    this.element.style.setProperty("--fill-pct", `${fillPercent}%`)
    this.element.style.setProperty("--overflow-pct", `${Math.min(overflowPercent, 55)}%`)
    this.element.classList.toggle("is-overflowing", overflowPercent > 0)
  }

  applySplashIfLargeJump() {
    const current = Number(this.currentValueValue || 0)
    const max = Math.max(Number(this.maxValueValue || 0), 1)
    const key = `jackbuddies:pot:${this.seasonYearValue}`
    const previous = Number(window.localStorage.getItem(key) || 0)
    const jump = current - previous

    if (jump > max * 0.15) {
      this.element.classList.add("is-splashing")
      window.setTimeout(() => this.element.classList.remove("is-splashing"), 1600)
    }

    window.localStorage.setItem(key, String(current))
  }

  bindTilt() {
    if (!window.DeviceOrientationEvent) return

    this.orientationHandler = (event) => {
      const gamma = Math.max(-20, Math.min(20, Number(event.gamma || 0)))
      this.jarTarget?.style.setProperty("--jar-tilt", `${gamma * 0.4}deg`)
      this.fillTarget?.style.setProperty("--liquid-tilt", `${gamma * 0.35}deg`)
    }

    window.addEventListener("deviceorientation", this.orientationHandler, { passive: true })
  }
}
