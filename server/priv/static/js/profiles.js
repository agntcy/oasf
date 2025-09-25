/*
 *  Copyright AGNTCY Contributors (https://github.com/agntcy)
 *  SPDX-License-Identifier: Apache-2.0
 */

function get_selected_profiles() {
  // First check URL parameters, then fall back to localStorage
  const urlParams = new URLSearchParams(window.location.search);
  const profilesParam = urlParams.get("profiles");

  if (profilesParam !== null) {
    return profilesParam === ""
      ? []
      : profilesParam.split(",").map((p) => p.trim());
  }

  return JSON.parse(localStorage.getItem("schema_profiles")) || [];
}

function set_selected_profiles(profiles) {
  localStorage.setItem("schema_profiles", JSON.stringify(profiles));
}

function select_profiles(selected) {
  if (selected && selected.length > 0) {
    return "&profiles=" + selected.join(",");
  }
  return "";
}

function init_selected_profiles(profiles) {
  if (profiles == null) profiles = get_selected_profiles();

  if (profiles.length == 0) {
    $(".oasf-class").each(function (i, e) {
      e.classList.remove("d-none");
    });
  } else {
    $.each(profiles, function (index, element) {
      $("#" + element.replace("/", "-")).prop("checked", true);
    });

    $(".oasf-class").each(function (i, e) {
      let n = 0;
      let list = (e.dataset["profiles"] || "").split(",");

      $.each(profiles, function (index, element) {
        if (list.indexOf(element) >= 0) n = n + 1;
      });

      if (profiles.length == n) e.classList.remove("d-none");
      else e.classList.add("d-none");
    });
  }
}

function init_class_profiles() {
  let profiles = $("#profiles-list :checkbox");
  profiles.on("change", function () {
    selected_profiles = [];
    profiles.each(function () {
      if (this.checked) selected_profiles.push(this.dataset["profile"]);
    });

    set_selected_profiles(selected_profiles);

    // Update URL with both extensions and profiles using the unified function
    const selected_extensions = get_selected_extensions();
    const params = build_url_params(selected_extensions, selected_profiles);

    // Update the URL
    window.location.search = params;
  });
}

function init_extension_profile_dependencies() {
  // Hide/show profiles based on extension selection on page load
  updateProfileVisibility();

  let extensions = $("#extensions-list :checkbox");
  extensions.on("change", function () {
    const extensionName = this.id;
    const isExtensionChecked = this.checked;

    if (!isExtensionChecked) {
      // When extension is unchecked, uncheck all profiles that belong to this extension
      let profiles = $("#profiles-list :checkbox");
      profiles.each(function () {
        const profileName = this.dataset["profile"];
        if (profileName && profileName.startsWith(extensionName + "/")) {
          this.checked = false;
        }
      });

      // Update the selected profiles list
      let selected_profiles = [];
      profiles.each(function () {
        if (this.checked) selected_profiles.push(this.dataset["profile"]);
      });

      set_selected_profiles(selected_profiles);
      init_selected_profiles(selected_profiles);
      if (typeof refresh_selected_profiles === "function") {
        refresh_selected_profiles();
      }
    }

    // Update profile visibility when extension selection changes
    updateProfileVisibility();
  });
}

function updateProfileVisibility() {
  let extensions = $("#extensions-list :checkbox");
  let profiles = $("#profiles-list .profile-item");

  // Get list of selected extensions
  let selectedExtensions = [];
  extensions.each(function () {
    if (this.checked) {
      selectedExtensions.push(this.id);
    }
  });

  // Show/hide profiles based on extension selection
  profiles.each(function () {
    const profileItem = $(this);
    const profileName = profileItem.data("profile-name");

    if (profileName) {
      // Check if this profile belongs to an extension
      let belongsToExtension = false;
      let shouldShow = true;

      for (let extension of selectedExtensions) {
        if (profileName.startsWith(extension + "/")) {
          belongsToExtension = true;
          break;
        }
      }

      // If profile belongs to an extension, only show it if that extension is selected
      if (profileName.includes("/")) {
        // This is an extension profile
        shouldShow = belongsToExtension;
      } else {
        // This is a core profile, always show it
        shouldShow = true;
      }

      if (shouldShow) {
        profileItem.show();
      } else {
        profileItem.hide();
        // Also uncheck hidden profiles
        profileItem.find("input[type='checkbox']").prop("checked", false);
      }
    }
  });

  // Update the selected profiles list after hiding profiles
  let selected_profiles = [];
  $("#profiles-list :checkbox:visible").each(function () {
    if (this.checked) selected_profiles.push(this.dataset["profile"]);
  });

  set_selected_profiles(selected_profiles);
  init_selected_profiles(selected_profiles);
  if (typeof refresh_selected_profiles === "function") {
    refresh_selected_profiles();
  }
}
