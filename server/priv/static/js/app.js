/*
 *  Copyright AGNTCY Contributors (https://github.com/agntcy)
 *  SPDX-License-Identifier: Apache-2.0
 */

function reset_home_page() {
  set_selected_extensions({});
  set_selected_profiles([]);
}

function select_extensions(selected) {
  if (selected) {
    const params = [];

    Object.entries(selected).forEach(function ([name, value]) {
      if (value) {
        params.push(name);
      }
    });

    return "?extensions=" + params.toString();
  }

  return "";
}

function build_url_params(extensions, profiles) {
  let params = [];

  // Add extensions parameter
  if (extensions) {
    const extensionParams = [];
    Object.entries(extensions).forEach(function ([name, value]) {
      if (value) {
        extensionParams.push(name);
      }
    });
    if (extensionParams.length > 0) {
      params.push("extensions=" + extensionParams.join(","));
    }
  }

  // Add profiles parameter
  if (profiles && profiles.length > 0) {
    params.push("profiles=" + profiles.join(","));
  }

  return params.length > 0 ? "?" + params.join("&") : "";
}

function get_selected_extensions() {
  // First check URL parameters, then fall back to localStorage
  const urlParams = new URLSearchParams(window.location.search);
  const extensionsParam = urlParams.get("extensions");

  if (extensionsParam !== null) {
    const extensions = {};
    if (extensionsParam !== "") {
      const extensionList = extensionsParam.split(",").map((e) => e.trim());
      extensionList.forEach((extension) => {
        extensions[extension] = true;
      });
    }
    return extensions;
  }

  return JSON.parse(localStorage.getItem("schema_extensions")) || {};
}

function set_selected_extensions(extensions) {
  localStorage.setItem("schema_extensions", JSON.stringify(extensions));
}

const selectedAttributesDefaultValues = [
  "base-class",
  "deprecated",
  "optional",
  "recommended",
  "classification",
  "context",
  "occurrence",
  "primary",
];
const selectedAttributesStorageKey = "selected-attributes";

function enable_option(name) {
  $(name).removeAttr("disabled");
}

function init_selected_attributes() {
  let selected = refresh_selected_profiles();
  init_attributes_select_picker($("#attributes-select"), selected);
}

function refresh_selected_profiles() {
  const data = window.localStorage.getItem(selectedAttributesStorageKey);
  let selected;

  if (data == null) {
    selected = selectedAttributesDefaultValues;
    window.localStorage.setItem(selectedAttributesStorageKey, selected);
  } else {
    if (data.length > 0) selected = data.split(",");
    else selected = [];
  }

  display_attributes(array_to_set(selected));
  return selected;
}

function init_attributes_select_picker(selection, selected) {
  selection.selectpicker();
  selection.selectpicker("val", selected);

  selection.on(
    "changed.bs.select",
    function (e, clickedIndex, isSelected, oldValues) {
      const values = [];

      for (let i = 0; i < this.length; i++) {
        if (this[i].selected) values.push(this[i].value);
        else hideAll = true;
      }
      window.localStorage.setItem(selectedAttributesStorageKey, values);
      display_attributes(array_to_set(values));
    },
  );
}

function display_attributes(options) {
  const table = document.getElementById("data-table");

  if (table != null) {
    // add CSS classes that are always shown
    options.add("class");
    options.add("required");
    options.add("no-group");
    options.add("no-profile");

    get_selected_profiles().forEach(function (elem) {
      options.add(elem.replace("/", "-"));
    });

    const rows = table.rows;
    const length = rows.length;

    for (let i = 1; i < length; i++) {
      const classList = rows[i].classList;
      const delta = intersection(array_to_set(classList), options);
      display_row(delta, classList);
    }
  }
}

function array_to_set(a) {
  return new Set(a);
}

function intersection(setA, setB) {
  let _intersection = new Set();
  for (let elem of setB) {
    if (setA.has(elem)) {
      _intersection.add(elem);
    }
  }
  return _intersection;
}

function display_row(set, classList) {
  const isDeprecated = classList.contains("deprecated");
  const showDeprecated =
    window.localStorage.getItem(showDeprecatedStorageKey) === "true";

  if (set.size == 4) {
    classList.remove("d-none");
  } else if (isDeprecated && showDeprecated) {
    // Show deprecated rows when show deprecated is enabled, regardless of other filters
    classList.remove("d-none");
  } else {
    classList.add("d-none");
  }
}

/* Search function that works for both tables and categories */
function searchInTable() {
  const input = document.getElementById("tableSearch");
  const filter = input.value.toUpperCase();

  // Check if we're on the categories page (has section.category elements)
  const categories = document.querySelectorAll("section.category");
  if (categories.length > 0) {
    searchInCategories(filter);
    return;
  }

  // Otherwise, search in tables
  const tbody = document.getElementsByClassName("searchable");
  for (let t = 0; t < tbody.length; t++) {
    let tr = tbody[t].children;

    // Loop through all table rows, and hide those who don't match the search query
    for (i = 0; i < tr.length; i++) {
      const row = tr[i];
      const children = row.children;
      let hide = true;
      if (children.length > 2) {
        for (let j = 0; hide && j < children.length - 1; j++) {
          const value = children[j].innerText;
          hide = value.toUpperCase().indexOf(filter) < 0;
        }
      } else {
        const value = children[0].innerText;
        hide = value.toUpperCase().indexOf(filter) < 0;
      }

      if (hide) row.style.display = "none";
      else row.style.display = "";
    }
  }
}

/* Search function for categories page */
function searchInCategories(filter) {
  const categories = document.querySelectorAll("section.category");

  categories.forEach((category) => {
    let categoryHasMatch = false;
    const categoryHeader = category.querySelector("header");
    const categoryName = categoryHeader
      ? categoryHeader.innerText.toUpperCase()
      : "";

    // Check if category name matches
    if (categoryName.indexOf(filter) >= 0) {
      categoryHasMatch = true;
    }

    // Check classes within the category
    const classes = category.querySelectorAll("div.oasf-class");
    let visibleClassCount = 0;

    classes.forEach((classDiv) => {
      const className = classDiv.innerText.toUpperCase();
      const classMatches = className.indexOf(filter) >= 0;

      if (filter === "" || classMatches || categoryHasMatch) {
        classDiv.style.display = "";
        visibleClassCount++;
      } else {
        classDiv.style.display = "none";
      }
    });

    // Show/hide the entire category based on matches
    if (filter === "" || categoryHasMatch || visibleClassCount > 0) {
      category.style.display = "";
    } else {
      category.style.display = "none";
    }
  });
}

function init_schema_buttons() {
  $("#btn-sample-data").on("click", function (event) {
    const url =
      "/sample" +
      window.location.pathname +
      "?profiles=" +
      get_selected_profiles().toString();
    window.open(url, "_blank");
  });

  $("#btn-json-schema").on("click", function (event) {
    const url =
      "/schema" +
      window.location.pathname +
      "?profiles=" +
      get_selected_profiles().toString();
    window.open(url, "_blank");
  });

  $("#btn-schema").on("click", function (event) {
    const url =
      "/api" +
      window.location.pathname +
      "?profiles=" +
      get_selected_profiles().toString();
    window.open(url, "_blank");
  });

  $("#btn-validate").on("click", function (event) {
    const entityType = $(this).data("entity-type");
    let url = "/doc/index.html#/Validation";
    if (entityType) {
      url += `/SchemaWeb.SchemaController.validate_${entityType}`;
    }
    window.open(url, "_blank");
  });
}

const showDeprecatedStorageKey = "show-deprecated";

function init_show_deprecated() {
  $(document).ready(function () {
    let checked = window.localStorage.getItem(showDeprecatedStorageKey);
    const showDeprecatedCheckbox = document.getElementById(
      "show-deprecated-global",
    );

    if (showDeprecatedCheckbox) {
      if (checked == null || checked == "false") {
        // Handling this case is needed in case where the prior state was checked _and_ local storage was
        // cleared _and_ the user agent (browser) comes back to this page with the back button. The browser
        // (at least Firefox) would keep the checkbox checked since that was the state of the UI.
        showDeprecatedCheckbox.checked = false;
        // Initialize deprecated elements as hidden without animation
        const deprecatedElements = document.querySelectorAll(".deprecated");
        deprecatedElements.forEach((element) => {
          element.classList.add("deprecated-hidden");
          // Ensure Bootstrap collapse state is also hidden
          element.classList.remove("show");
        });
      } else if (checked == "true") {
        showDeprecatedCheckbox.checked = true;
        // Initialize deprecated elements as visible without animation
        const deprecatedElements = document.querySelectorAll(".deprecated");
        deprecatedElements.forEach((element) => {
          element.classList.add("deprecated-visible");
          // Ensure Bootstrap collapse state is also shown
          element.classList.add("show");
        });
      }
    }

    // Update container state
    updateShowDeprecatedState(checked == "true");

    // Refresh the attribute display to show/hide deprecated rows based on stored state
    const data = window.localStorage.getItem(selectedAttributesStorageKey);
    let selected;
    if (data == null) {
      selected = selectedAttributesDefaultValues;
    } else {
      if (data.length > 0) selected = data.split(",");
      else selected = [];
    }
    display_attributes(array_to_set(selected));
  });
}

function on_click_show_deprecated(checkbox) {
  if (checkbox.checked) {
    window.localStorage.setItem(showDeprecatedStorageKey, "true");
    smoothShowDeprecated(true);
  } else {
    window.localStorage.setItem(showDeprecatedStorageKey, "false");
    smoothShowDeprecated(false);
  }

  // Update container active state
  updateShowDeprecatedState(checkbox.checked);

  // Refresh the attribute display to show/hide deprecated rows
  const data = window.localStorage.getItem(selectedAttributesStorageKey);
  let selected;
  if (data == null) {
    selected = selectedAttributesDefaultValues;
  } else {
    if (data.length > 0) selected = data.split(",");
    else selected = [];
  }
  display_attributes(array_to_set(selected));
}

function smoothShowDeprecated(show) {
  const deprecatedElements = document.querySelectorAll(".deprecated");

  deprecatedElements.forEach((element) => {
    if (show) {
      // Remove hidden class and add showing class for smooth animation
      element.classList.remove("deprecated-hidden");
      element.classList.add("deprecated-showing");

      // Use requestAnimationFrame for smoother animation
      requestAnimationFrame(() => {
        element.classList.remove("deprecated-showing");
        element.classList.add("deprecated-visible");
      });
    } else {
      // Add hiding class for smooth animation
      element.classList.remove("deprecated-visible");
      element.classList.add("deprecated-hiding");

      // Hide after animation completes
      setTimeout(() => {
        element.classList.remove("deprecated-hiding");
        element.classList.add("deprecated-hidden");
      }, 300);
    }
  });
}

function updateShowDeprecatedState(isActive) {
  const container = document.querySelector(".show-deprecated-container");
  if (container) {
    if (isActive) {
      container.classList.add("active");
    } else {
      container.classList.remove("active");
    }
  }
}

// Sidebar collapse functionality
function initSidebarToggle() {
  const sidebarToggle = document.getElementById("sidebar-toggle");
  const sidebar = document.querySelector(".navbar.fixed-left");
  const body = document.body;
  const toggleIcon = document.getElementById("sidebar-toggle-icon");

  if (!sidebarToggle || !sidebar) return;

  // Function to check if we're on mobile
  function isMobile() {
    return window.innerWidth <= 768;
  }

  // Function to apply initial state based on screen size
  function applyInitialState() {
    // Clear all classes first
    sidebar.classList.remove("collapsed", "expanded");
    body.classList.remove("sidebar-collapsed", "sidebar-expanded");

    if (isMobile()) {
      // Mobile: check localStorage to remember sidebar state
      const isMobileExpanded =
        localStorage.getItem("sidebar-mobile-expanded") === "true";
      if (isMobileExpanded) {
        sidebar.classList.add("expanded");
        body.classList.add("sidebar-expanded");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-right");
          toggleIcon.classList.add("fa-chevron-left");
        }
      } else {
        // Default mobile state: collapsed
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-left");
          toggleIcon.classList.add("fa-chevron-right");
        }
      }
    } else {
      // Desktop: expanded by default, can be collapsed
      const isCollapsed = localStorage.getItem("sidebar-collapsed") === "true";
      if (isCollapsed) {
        sidebar.classList.add("collapsed");
        body.classList.add("sidebar-collapsed");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-left");
          toggleIcon.classList.add("fa-chevron-right");
        }
      } else {
        // Default desktop state: expanded
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-right");
          toggleIcon.classList.add("fa-chevron-left");
        }
      }
    }
  }

  // Apply initial state
  applyInitialState();

  // Single click handler that works for both mobile and desktop
  sidebarToggle.addEventListener("click", function () {
    if (isMobile()) {
      // Mobile logic
      const isCurrentlyExpanded = sidebar.classList.contains("expanded");

      if (isCurrentlyExpanded) {
        sidebar.classList.remove("expanded");
        body.classList.remove("sidebar-expanded");
        localStorage.setItem("sidebar-mobile-expanded", "false");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-left");
          toggleIcon.classList.add("fa-chevron-right");
        }
      } else {
        sidebar.classList.add("expanded");
        body.classList.add("sidebar-expanded");
        localStorage.setItem("sidebar-mobile-expanded", "true");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-right");
          toggleIcon.classList.add("fa-chevron-left");
        }
      }
    } else {
      // Desktop logic
      const isCurrentlyCollapsed = sidebar.classList.contains("collapsed");

      if (isCurrentlyCollapsed) {
        sidebar.classList.remove("collapsed");
        body.classList.remove("sidebar-collapsed");
        localStorage.setItem("sidebar-collapsed", "false");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-right");
          toggleIcon.classList.add("fa-chevron-left");
        }
      } else {
        sidebar.classList.add("collapsed");
        body.classList.add("sidebar-collapsed");
        localStorage.setItem("sidebar-collapsed", "true");
        if (toggleIcon) {
          toggleIcon.classList.remove("fa-chevron-left");
          toggleIcon.classList.add("fa-chevron-right");
        }
      }
    }
  });

  // Handle window resize to reapply state when switching between mobile/desktop
  window.addEventListener("resize", function () {
    applyInitialState();
  });
}

// Modern enhancements
document.addEventListener("DOMContentLoaded", function () {
  // Initialize sidebar toggle
  initSidebarToggle();

  // Enhance search input with focus styling
  const searchInput = document.getElementById("tableSearch");
  if (searchInput) {
    searchInput.addEventListener("focus", function () {
      this.style.borderColor = "var(--accent-color)";
      this.style.boxShadow = "0 0 0 3px rgba(0, 164, 183, 0.1)";
    });

    searchInput.addEventListener("blur", function () {
      this.style.borderColor = "var(--border-color)";
      this.style.boxShadow = "none";
    });
  }
});
