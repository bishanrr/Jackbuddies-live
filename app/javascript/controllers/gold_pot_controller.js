import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fillLiquid", "progressFill", "progressPct", "amountValue", "coins"]
  static values = { currentValue: Number, maxValue: Number }

  connect() {
    this.updateDisplay()
    this.spawnBurst()
  }

  updateDisplay() {
    const total = Number(this.currentValueValue || 0)
    const goal = Math.max(Number(this.maxValueValue || 1), 1)
    const pct = Math.max(0, (total / goal) * 100)
    const barPct = Math.min(pct, 100)

    // Keep the pot visual static; progress is represented only by the bar below.
    this.fillLiquidTarget.style.height = "0%"
    this.progressFillTarget.style.width = `${barPct}%`
    this.progressPctTarget.textContent = `${pct.toFixed(1)}%`
    this.amountValueTarget.textContent = this.formatINR(total)
  }

  spawnBurst() {
    const coinCount = 10
    for (let i = 0; i < coinCount; i += 1) {
      this.spawnCoin(i)
    }
  }

  spawnCoin(index) {
    const coin = document.createElement("div")
    coin.className = "gp-coin"
    this.coinsTarget.appendChild(coin)

    coin.style.setProperty("--sx", `${Math.random() * 200 - 100}px`)
    coin.style.setProperty("--sy", "-80px")
    coin.style.setProperty("--mx", `${Math.random() * 100 - 50}px`)
    coin.style.setProperty("--my", `${Math.random() * -60 - 20}px`)
    coin.style.setProperty("--ex", `${Math.random() * 40 - 20}px`)
    coin.style.setProperty("--ey", "120px")
    coin.style.setProperty("--rot", `${(Math.random() > 0.5 ? 1 : -1) * (Math.random() * 360 + 180)}deg`)
    coin.style.setProperty("--delay", `${index * 0.09}s`)
    coin.style.setProperty("--dur", `${0.9 + Math.random() * 0.4}s`)
    coin.style.left = "calc(50% - 19px)"
    coin.style.top = "60px"

    requestAnimationFrame(() => coin.classList.add("fly"))
    const life = (parseFloat(coin.style.getPropertyValue("--dur")) + parseFloat(coin.style.getPropertyValue("--delay"))) * 1000 + 120
    setTimeout(() => coin.remove(), life)
  }

  formatINR(n) {
    return `₹ ${n.toLocaleString("en-IN")}`
  }
}
