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

    return '?extensions=' + params.toString()
  }

  return '';
}

function get_selected_extensions() {
  return JSON.parse(localStorage.getItem('schema_extensions')) || {};
}

function set_selected_extensions(extensions) {
  localStorage.setItem("schema_extensions", JSON.stringify(extensions));
}

const selectedAttributesDefaultValues = ["base-class", "deprecated", "optional", "recommended", "classification", "context", "occurrence", "primary"];
const selectedAttributesStorageKey = "selected-attributes"

function hide(name) {
  $(name).addClass('d-none');
}

function show(name) {
  $(name).removeClass('d-none');
}

function enable_option(name) {
  $(name).removeAttr('disabled');
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
    if (data.length > 0)
      selected = data.split(",");
    else
      selected = [];
  }

  display_attributes(array_to_set(selected));
  return selected;
}

function init_attributes_select_picker(selection, selected) {
  selection.selectpicker();
  selection.selectpicker('val', selected);

  selection.on('changed.bs.select', function (e, clickedIndex, isSelected, oldValues) {
    const values = [];

    for (let i = 0; i < this.length; i++) {
      if (this[i].selected)
        values.push(this[i].value);
      else
        hideAll = true;
    }
    window.localStorage.setItem(selectedAttributesStorageKey, values);
    display_attributes(array_to_set(values));
  });
}

function display_attributes(options) {
  const table = document.getElementById('data-table');

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
    let _intersection = new Set()
    for (let elem of setB) {
        if (setA.has(elem)) {
            _intersection.add(elem)
        }
    }
    return _intersection
}

function display_row(set, classList) {
  if (set.size == 4)
    classList.remove('d-none');
  else
    classList.add('d-none');
}

/* Table search function */
function searchInTable() {
  const input = document.getElementById("tableSearch");
  const filter = input.value.toUpperCase();
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
      }
      else {
        const value = children[0].innerText;
        hide = value.toUpperCase().indexOf(filter) < 0;
      }

      if (hide)
        row.style.display = "none";
      else
        row.style.display = "";
    }
  }
}

function init_schema_buttons() {
  $('#btn-sample-data').on('click', function(event) {
    const url = '/sample' + window.location.pathname + "?profiles=" + get_selected_profiles().toString();
    window.open(url,'_blank');
  });

  $('#btn-json-schema').on('click', function(event) {
    const url = '/schema' + window.location.pathname + "?profiles=" + get_selected_profiles().toString();
    window.open(url,'_blank');
  });

  $('#btn-schema').on('click', function(event) {
    const url = '/api' + window.location.pathname + "?profiles=" + get_selected_profiles().toString();
    window.open(url,'_blank');
  });
}

const showDeprecatedStorageKey = "show-deprecated";

function init_show_deprecated() {
  $(document).ready(function () {
    let checked = window.localStorage.getItem(showDeprecatedStorageKey);
    if (checked == null || checked == "false") {
      // Handling this case is needed in case where the prior state was checked _and_ local storage was
      // cleared _and_ the user agent (browser) comes back to this page with the back button. The browser
      // (at least Firefox) would keep the checkbox checked since that was the state of the UI.
      document.getElementById("show-deprecated").checked = false;
      $(".deprecated").collapse('hide')
    } else if (checked == "true") {
      document.getElementById("show-deprecated").checked = true;
      $(".deprecated").collapse('show')
    }
  });
}

function on_click_show_deprecated(checkbox) {
  if (checkbox.checked) {
    window.localStorage.setItem(showDeprecatedStorageKey, "true");
  } else {
    window.localStorage.setItem(showDeprecatedStorageKey, "false");
  }
}
