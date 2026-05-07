document.addEventListener("DOMContentLoaded", () => {
  const menuButton = document.querySelector(".menu-toggle");
  const nav = document.querySelector("#site-nav");

  if (menuButton && nav) {
    menuButton.addEventListener("click", () => {
      const isOpen = nav.classList.toggle("open");
      menuButton.setAttribute("aria-expanded", String(isOpen));
    });

    nav.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => {
        nav.classList.remove("open");
        menuButton.setAttribute("aria-expanded", "false");
      });
    });
  }

  const form = document.querySelector("#contactForm");
  const status = document.querySelector("#formStatus");

  if (form && status) {
    form.addEventListener("submit", () => {
      const button = form.querySelector("button[type='submit']");

      if (button) {
        button.disabled = true;
        button.textContent = "Sending...";
      }

      status.textContent = "Sending your request securely...";
      status.className = "form-status";
    });
  }
});
