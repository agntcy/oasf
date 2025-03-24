/*
 *  Copyright AGNTCY Contributors (https://github.com/agntcy)
 *  SPDX-License-Identifier: Apache-2.0
 */


function get_selected_profiles() {
  return JSON.parse(localStorage.getItem("schema_profiles")) || [];
}

function set_selected_profiles(profiles) {
  localStorage.setItem("schema_profiles", JSON.stringify(profiles));
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
  let profiles = $("#checkbox-profiles :checkbox");
  profiles.on("change", function () {
    selected_profiles = [];
    profiles.each(function () {
      if (this.checked) selected_profiles.push(this.dataset["profile"]);
    });

    set_selected_profiles(selected_profiles);
    init_selected_profiles(selected_profiles);
    refresh_selected_profiles();
  });
}
