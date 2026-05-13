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
});

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
    images.slice(1, 5).forEach((projectImage) => {
      const thumb = document.createElement("img");
      thumb.src = projectImage.image;
      thumb.alt = projectImage.alt || project.alt || `${project.title || "Hands-On Idaho project"} photo`;
      thumb.loading = "lazy";
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
