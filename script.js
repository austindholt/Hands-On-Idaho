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

      status.textContent = "Sending your request. After it goes through, you can text photos to (208) 861-2302 for a faster estimate.";
      status.className = "form-status";
    });
  }

  initProjectGalleries();
  initStaticProjectLightboxes();
});

let activeProjectLightbox = null;

async function initProjectGalleries() {
  const gallery = document.querySelector("[data-project-gallery]");
  const featured = document.querySelector("[data-featured-projects]");

  if (!gallery && !featured) {
    return;
  }

  try {
    const response = await fetch("projects.json", { cache: "no-cache" });
    if (!response.ok) {
      throw new Error("Project manifest unavailable");
    }

    const projects = (await response.json()).filter((project) => {
      return project && getProjectImages(project).length && project.hidden !== true;
    });

    if (!projects.length) {
      return;
    }

    if (gallery) {
      renderProjectCards(gallery, projects);
    }

    if (featured) {
      renderProjectCards(featured, pickWeeklyFeaturedProjects(projects, 3));
    }
  } catch (error) {
    // Keep the static fallback cards if the manifest cannot be loaded.
    console.warn(error);
  }
}

function pickWeeklyFeaturedProjects(projects, count) {
  const pool = projects.filter((project) => project.featured !== false);

  if (pool.length <= count) {
    return pool;
  }

  const now = new Date();
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const weekIndex = Math.floor((now - startOfYear) / (7 * 24 * 60 * 60 * 1000));
  const selected = [];

  for (let index = 0; index < count; index += 1) {
    selected.push(pool[(weekIndex + index) % pool.length]);
  }

  return selected;
}

function renderProjectCards(container, projects) {
  container.replaceChildren(...projects.map(createProjectCard));
}

function createProjectCard(project) {
  const article = document.createElement("article");
  article.className = "project-card";

  const images = getProjectImages(project);
  const primaryImage = images[0];
  const imageWrap = document.createElement("div");
  imageWrap.className = "project-image-wrap";

  const image = document.createElement("img");
  image.src = primaryImage.image;
  image.alt = primaryImage.alt || project.alt || `${project.title || "Hands-On Idaho project"} in ${project.area || "the Treasure Valley"}`;
  image.loading = "lazy";
  makeProjectImageInteractive(image, images, 0, project.title);
  image.addEventListener("error", () => {
    imageWrap.classList.add("missing-image");
    image.remove();
  });

  imageWrap.append(image);
  if (images.length > 1) {
    const count = document.createElement("span");
    count.className = "project-photo-count";
    count.textContent = `${images.length} photos`;
    imageWrap.append(count);
  }

  const content = document.createElement("div");
  content.className = "project-content";

  const eyebrow = document.createElement("p");
  eyebrow.className = "eyebrow";
  eyebrow.textContent = [project.service, project.area].filter(Boolean).join(" • ");

  const title = document.createElement("h2");
  title.textContent = project.title || "Project Photo";

  const description = document.createElement("p");
  description.textContent = project.description || "Real Hands-On Idaho project photo from around the Treasure Valley.";

  content.append(eyebrow, title, description);

  if (images.length > 1) {
    const thumbnails = document.createElement("div");
    thumbnails.className = "project-thumbnails";
    images.slice(1, 5).forEach((projectImage, thumbnailIndex) => {
      const thumb = document.createElement("img");
      thumb.src = projectImage.image;
      thumb.alt = projectImage.alt || project.alt || `${project.title || "Hands-On Idaho project"} photo`;
      thumb.loading = "lazy";
      makeProjectImageInteractive(thumb, images, thumbnailIndex + 1, project.title);
      thumbnails.append(thumb);
    });
    content.append(thumbnails);
  }

  if (Array.isArray(project.tags) && project.tags.length) {
    const tags = document.createElement("div");
    tags.className = "project-tags";
    project.tags.slice(0, 4).forEach((tag) => {
      const item = document.createElement("span");
      item.className = "project-tag";
      item.textContent = tag;
      tags.append(item);
    });
    content.append(tags);
  }

  if (project.needsReview) {
    const review = document.createElement("p");
    review.className = "project-review-note";
    review.textContent = "Photo details need final review.";
    content.append(review);
  }

  const link = document.createElement("a");
  link.className = "text-link";
  link.href = "contact.html";
  link.textContent = project.cta || "Request a project estimate";
  content.append(link);

  article.append(imageWrap, content);
  return article;
}

function getProjectImages(project) {
  if (Array.isArray(project.images) && project.images.length) {
    return project.images.filter((image) => image && image.image);
  }

  if (project.image) {
    return [{
      image: project.image,
      alt: project.alt,
      caption: project.title
    }];
  }

  return [];
}

function initStaticProjectLightboxes() {
  document.querySelectorAll(".project-card").forEach((card) => {
    const imageNodes = Array.from(card.querySelectorAll(".project-image-wrap img, .project-thumbnails img"));

    if (!imageNodes.length) {
      return;
    }

    const images = imageNodes.reduce((items, image) => {
      const src = image.getAttribute("src");

      if (!src || items.some((item) => item.image === src)) {
        return items;
      }

      items.push({
        image: src,
        alt: image.getAttribute("alt") || "Hands-On Idaho project photo",
        caption: image.getAttribute("alt") || ""
      });

      return items;
    }, []);

    const title = card.querySelector("h2, h3")?.textContent?.trim() || "Project Photos";

    imageNodes.forEach((image) => {
      const imageIndex = images.findIndex((item) => item.image === image.getAttribute("src"));
      makeProjectImageInteractive(image, images, Math.max(imageIndex, 0), title);
    });
  });
}

function makeProjectImageInteractive(image, images, index, title) {
  if (!image || !Array.isArray(images) || !images.length || image.dataset.lightboxReady === "true") {
    return;
  }

  image.dataset.lightboxReady = "true";
  image.classList.add("project-lightbox-trigger");
  image.setAttribute("role", "button");
  image.setAttribute("tabindex", "0");
  image.setAttribute("aria-label", `Open ${title || "project"} photo ${index + 1} of ${images.length}`);

  image.addEventListener("click", () => {
    openProjectLightbox(images, index, title);
  });

  image.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      openProjectLightbox(images, index, title);
    }
  });
}

function openProjectLightbox(images, startIndex = 0, title = "Project Photos") {
  const usableImages = images.filter((image) => image && image.image);

  if (!usableImages.length) {
    return;
  }

  const lightbox = ensureProjectLightbox();
  activeProjectLightbox = {
    images: usableImages,
    index: Math.min(Math.max(startIndex, 0), usableImages.length - 1),
    title
  };

  lightbox.root.hidden = false;
  document.body.classList.add("lightbox-open");
  updateProjectLightbox();
  lightbox.close.focus();
}

function ensureProjectLightbox() {
  const existing = document.querySelector("[data-project-lightbox]");

  if (existing) {
    return {
      root: existing,
      image: existing.querySelector("[data-lightbox-image]"),
      caption: existing.querySelector("[data-lightbox-caption]"),
      count: existing.querySelector("[data-lightbox-count]"),
      close: existing.querySelector(".project-lightbox-close"),
      previous: existing.querySelector("[data-lightbox-previous]"),
      next: existing.querySelector("[data-lightbox-next]")
    };
  }

  const root = document.createElement("div");
  root.className = "project-lightbox";
  root.dataset.projectLightbox = "true";
  root.hidden = true;

  root.innerHTML = `
    <div class="project-lightbox-backdrop" data-lightbox-close></div>
    <div class="project-lightbox-dialog" role="dialog" aria-modal="true" aria-label="Project photo viewer">
      <button class="project-lightbox-close" type="button" data-lightbox-close aria-label="Close photo viewer">Close</button>
      <button class="project-lightbox-nav project-lightbox-prev" type="button" data-lightbox-previous aria-label="Previous project photo">&lt;</button>
      <figure class="project-lightbox-figure">
        <img data-lightbox-image alt="">
        <figcaption>
          <span data-lightbox-caption></span>
          <span data-lightbox-count></span>
        </figcaption>
      </figure>
      <button class="project-lightbox-nav project-lightbox-next" type="button" data-lightbox-next aria-label="Next project photo">&gt;</button>
    </div>
  `;

  document.body.append(root);

  const lightbox = {
    root,
    image: root.querySelector("[data-lightbox-image]"),
    caption: root.querySelector("[data-lightbox-caption]"),
    count: root.querySelector("[data-lightbox-count]"),
    close: root.querySelector(".project-lightbox-close"),
    previous: root.querySelector("[data-lightbox-previous]"),
    next: root.querySelector("[data-lightbox-next]")
  };

  root.querySelectorAll("[data-lightbox-close]").forEach((button) => {
    button.addEventListener("click", closeProjectLightbox);
  });

  lightbox.previous.addEventListener("click", () => moveProjectLightbox(-1));
  lightbox.next.addEventListener("click", () => moveProjectLightbox(1));

  document.addEventListener("keydown", (event) => {
    if (!activeProjectLightbox || root.hidden) {
      return;
    }

    if (event.key === "Escape") {
      closeProjectLightbox();
    }

    if (event.key === "ArrowLeft") {
      moveProjectLightbox(-1);
    }

    if (event.key === "ArrowRight") {
      moveProjectLightbox(1);
    }
  });

  return lightbox;
}

function updateProjectLightbox() {
  if (!activeProjectLightbox) {
    return;
  }

  const lightbox = ensureProjectLightbox();
  const { images, index, title } = activeProjectLightbox;
  const current = images[index];
  const caption = current.caption || current.alt || title || "Hands-On Idaho project photo";

  lightbox.image.src = current.image;
  lightbox.image.alt = current.alt || caption;
  lightbox.caption.textContent = caption;
  lightbox.count.textContent = images.length > 1 ? `${index + 1} of ${images.length}` : "";
  lightbox.previous.hidden = images.length <= 1;
  lightbox.next.hidden = images.length <= 1;
}

function moveProjectLightbox(direction) {
  if (!activeProjectLightbox) {
    return;
  }

  const { images } = activeProjectLightbox;
  activeProjectLightbox.index = (activeProjectLightbox.index + direction + images.length) % images.length;
  updateProjectLightbox();
}

function closeProjectLightbox() {
  const lightbox = document.querySelector("[data-project-lightbox]");

  if (lightbox) {
    lightbox.hidden = true;
  }

  activeProjectLightbox = null;
  document.body.classList.remove("lightbox-open");
}
