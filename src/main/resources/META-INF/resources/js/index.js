async function getTranslation(locale, name) {
  const response = await fetch(`../rsc/locale/translate/${locale}/${name}`);
  if (!response.ok) {
    throw new Error(`HTTP error ${response.status}`);
  }
  return await response.text();
}

async function getDocumentCount() {
  const response = await fetch('../api/v1/search?q=objectType:mods AND state:published&rows=0&wt=json');
  if (!response.ok) {
    throw new Error(`HTTP error ${response.status}`);
  }
  const data = await response.json();
  return data?.response?.numFound;
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

document.addEventListener('DOMContentLoaded', async () => {
  document.getElementById('leo-searchInput')?.addEventListener('submit', ignoreEmptyFieldsOnSubmit);
  const input = document.getElementById('project-searchInput');
  if (input) {
    try {
      const placeholder = await getTranslation(currentLang, 'leopoldina.index.search.placeholder');
      const count = await getDocumentCount();
      input.placeholder = placeholder.replace('{0}', count.toLocaleString('de-DE'));
    } catch {
      console.error('Error updating search placeholder:', err);
    }
  }
});
