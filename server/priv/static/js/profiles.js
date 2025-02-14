// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//   http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

function get_selected_profiles() {
  return JSON.parse(localStorage.getItem('schema_profiles')) || [];
}

function set_selected_profiles(profiles) {
  localStorage.setItem("schema_profiles", JSON.stringify(profiles));
}

function init_selected_profiles(profiles) {
  if (profiles == null)
    profiles = get_selected_profiles();

  if (profiles.length == 0) {
    $(".oasf-class").each(function(i, e) {
      e.classList.remove('d-none');
    });
  } else {
    $.each(profiles, function(index, element) {
      $("#" + element.replace("/", "-")).prop('checked', true);
    });

    $(".oasf-class").each(function(i, e) {
      let n = 0;
      let list = (e.dataset["profiles"] || "").split(",");
      
      $.each(profiles, function(index, element) {
        if (list.indexOf(element) >= 0)
          n = n + 1;
      });

      if (profiles.length == n)
        e.classList.remove('d-none');
      else
        e.classList.add('d-none');
    });
  }
}

function init_class_profiles() {
  let profiles = $("#checkbox-profiles :checkbox");
  profiles.on("change", function() {
    selected_profiles = [];
    profiles.each(function(){
      if (this.checked)
        selected_profiles.push(this.dataset["profile"])
    });

    set_selected_profiles(selected_profiles);
    init_selected_profiles(selected_profiles);
    refresh_selected_profiles();
  });
}
