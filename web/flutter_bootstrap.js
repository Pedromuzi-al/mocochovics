{{flutter_js}}
{{flutter_build_config}}

(() => {
  const startup = document.getElementById('app-startup');
  const message = document.getElementById('startup-message');
  const retry = document.getElementById('startup-retry');
  let rendered = false;
  retry?.addEventListener('click', () => window.location.reload());

  function showRecovery(text) {
    if (rendered || !startup) return;
    message.textContent = text;
    retry.hidden = false;
  }

  const timeout = setTimeout(() => showRecovery(
    'Está levando mais tempo que o esperado. Confira sua conexão ou atualize a página.',
  ), 20000);

  window.addEventListener('flutter-first-frame', () => {
    rendered = true;
    clearTimeout(timeout);
    if (startup) startup.hidden = true;
  }, {once: true});

  _flutter.loader.load({
    onEntrypointLoaded: async (engineInitializer) => {
      try {
        const appRunner = await engineInitializer.initializeEngine();
        await appRunner.runApp();
      } catch (error) {
        console.error('Falha ao iniciar o aplicativo.', error);
        showRecovery('Não foi possível abrir o aplicativo. Confira sua conexão e tente novamente.');
      }
    },
  }).catch((error) => {
    console.error('Falha ao carregar o aplicativo.', error);
    showRecovery('Não foi possível carregar o aplicativo. Confira sua conexão e tente novamente.');
  });
})();
