function replaceMaskedEmails() {
  document.querySelectorAll('span.madress').forEach(span => {
    const address = span.textContent.replace(' [at] ', '@');
    const link = document.createElement('a');
    link.href = `mailto:${address}`;
    link.textContent = address;
    span.replaceWith(link);
  });
}

function ignoreEmptyFieldsOnSubmit(event) {
  const form = event.currentTarget;
  const inputs = form.querySelectorAll('input');
  inputs.forEach(input => {
    if (!input.value) {
      input.dataset.nameBackup = input.name;
      input.removeAttribute('name');
    }
  });
  // Restore field names after the form is submitted
  // setTimeout ensures this runs after the submit event completes
  setTimeout(() => {
    inputs.forEach(input => {
      if (input.dataset.nameBackup) {
        input.name = input.dataset.nameBackup;
        delete input.dataset.nameBackup;
      }
    });
  }, 0);
}

function removeGenreOptions(values) {
  const select = document.querySelector('select#genre');
  if (!select) {
    return;
  }
  Array.from(select.options).forEach(option => {
    if (values.includes(option.value)) {
      option.remove();
    }
  });
}

function setupGenreObserver(values) {
  const observer = new MutationObserver(() => {
    removeGenreOptions(values);
  });
  observer.observe(document.body, {childList: true, subtree: true});
  return observer;
}

function init() {
  const genresToRemove = ['series', 'journal'];
  setupGenreObserver(genresToRemove);
  document.querySelector('form.searchfield_box')?.addEventListener('submit', ignoreEmptyFieldsOnSubmit);
  replaceMaskedEmails();
  removeGenreOptions(genresToRemove);
}

document.addEventListener('DOMContentLoaded', init);
