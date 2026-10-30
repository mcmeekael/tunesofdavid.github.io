(() => {
  'use strict';
  const config = window.TOD_CONFIG || { DEMO_MODE: true, API_BASE_URL: '' };
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
  const state = { authAction: 'login', authRole: 'musician', activeGig: null };

  // Sample content is clearly labelled. It is not connected to a live jobs database.
  const gigs = [
    {id:1,title:'Wedding reception bassist',specialty:'Bass Guitarist',location:'Ikeja, Lagos',city:'Lagos',date:'2026-11-14',dateLabel:'Sat, 14 Nov 2026',start:'16:00',end:'22:00',pay:35000,description:'Live band set for a wedding reception. Bring your own bass and arrive for sound check.',poster:'Sample employer',needs:'Bass guitar and live wedding experience',isPreview:true},
    {id:2,title:'Sunday service keyboardist',specialty:'Keyboardist',location:'Gwarinpa, Abuja',city:'Abuja',date:'2026-11-08',dateLabel:'Sun, 8 Nov 2026',start:'07:00',end:'11:00',pay:18000,description:'Play contemporary worship and hymns for a morning service. Set list shared before the day.',poster:'Sample employer',needs:'Keyboard / piano',isPreview:true},
    {id:3,title:'Live band drummer',specialty:'Drummer',location:'GRA, Port Harcourt',city:'Port Harcourt',date:'2026-11-21',dateLabel:'Sat, 21 Nov 2026',start:'18:00',end:'23:00',pay:28000,description:'Join a live band for a private celebration. Drum kit available at the venue.',poster:'Sample employer',needs:'Acoustic drum kit and live performance',isPreview:true},
    {id:4,title:'Highlife lead guitarist',specialty:'Lead Guitarist',location:'Enugu',city:'Enugu',date:'2026-11-28',dateLabel:'Sat, 28 Nov 2026',start:'17:00',end:'22:30',pay:32000,description:'Traditional highlife set with an experienced event band. Rehearsal call is included.',poster:'Sample employer',needs:'Lead guitar and highlife repertoire',isPreview:true},
    {id:5,title:'Saxophonist for dinner event',specialty:'Saxophonist',location:'Victoria Island, Lagos',city:'Lagos',date:'2026-11-12',dateLabel:'Thu, 12 Nov 2026',start:'19:00',end:'22:00',pay:25000,description:'Smooth jazz and soul selections for a corporate dinner. Backing tracks will be supplied.',poster:'Sample employer',needs:'Alto or tenor saxophone',isPreview:true},
    {id:6,title:'Trumpeter for cultural event',specialty:'Trumpeter',location:'Owerri, Imo',city:'Owerri',date:'2026-12-05',dateLabel:'Sat, 5 Dec 2026',start:'14:00',end:'19:00',pay:22000,description:'Brass feature for a cultural celebration. Event organiser will provide the full schedule.',poster:'Sample employer',needs:'Trumpet, confident live performance',isPreview:true},
    {id:7,title:'Percussionist for live set',specialty:'Percussionist',location:'Lekki, Lagos',city:'Lagos',date:'2026-11-19',dateLabel:'Thu, 19 Nov 2026',start:'18:30',end:'22:30',pay:24000,description:'Add conga and hand percussion to a contemporary Afro-highlife set.',poster:'Sample employer',needs:'Conga / hand percussion',isPreview:true},
    {id:8,title:'Lead vocalist for private party',specialty:'Singer',location:'Asaba, Delta',city:'Asaba',date:'2026-11-30',dateLabel:'Mon, 30 Nov 2026',start:'16:00',end:'21:00',pay:30000,description:'Lead vocals for a private event with a house band. Repertoire discussion happens ahead of time.',poster:'Sample employer',needs:'Lead singing and live band',isPreview:true}
  ];
  const money = amount => new Intl.NumberFormat('en-NG',{style:'currency',currency:'NGN',maximumFractionDigits:0}).format(amount).replace('NGN','₦');
  const safe = value => String(value).replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
  const glyph = (symbol) => `<span class="meta-icon" aria-hidden="true">${symbol}</span>`;

  function renderGigs() {
    const root = $('#gigs-grid');
    if (!root) return;
    const specialty = ($('#specialty-filter')?.value || '').toLowerCase();
    const location = ($('#location-filter')?.value || '').trim().toLowerCase();
    const sort = $('#sort-gigs')?.value || 'recommended';
    let rows = gigs.filter(g => (!specialty || g.specialty.toLowerCase() === specialty) && (!location || `${g.location} ${g.city}`.toLowerCase().includes(location)));
    if (sort === 'pay-high') rows.sort((a,b) => b.pay - a.pay);
    if (sort === 'date') rows.sort((a,b) => a.date.localeCompare(b.date));
    root.innerHTML = rows.map(g => `
      <article class="gig-card">
        <div class="gig-topline"><span class="gig-category">${safe(g.specialty)}</span><span class="demo-badge">Preview</span></div>
        <h3>${safe(g.title)}</h3>
        <p class="gig-description">${safe(g.description)}</p>
        <div class="gig-meta"><span>${glyph('⌖')}${safe(g.location)}</span><span>${glyph('◷')}${safe(g.dateLabel)} · ${safe(g.start)}–${safe(g.end)}</span></div>
        <div class="gig-bottom"><div class="gig-pay"><strong>${money(g.pay)}</strong><span>+ ₦1,000 reserve at booking</span></div><button type="button" class="button button-outline" data-gig-details="${g.id}">View gig <span aria-hidden="true">↗</span></button></div>
      </article>`).join('');
    $('#gigs-empty')?.classList.toggle('hidden', rows.length > 0);
    const label = $('#gig-results-label');
    if (label) label.textContent = `${rows.length} illustrative gig preview${rows.length === 1 ? '' : 's'}`;
  }

  function showToast(title, body) {
    const region = $('#toast-region');
    if (!region) return;
    const node = document.createElement('div');
    node.className = 'toast';
    node.setAttribute('role','status');
    node.innerHTML = `<strong>${safe(title)}</strong><br>${safe(body)}`;
    region.appendChild(node);
    window.setTimeout(() => node.remove(), 6500);
  }

  function modalOpen(modal) {
    if (!modal) return;
    modal.classList.remove('hidden');
    document.body.classList.add('modal-open');
  }
  function modalClose(modal) {
    if (!modal) return;
    modal.classList.add('hidden');
    if ($$('.modal-backdrop:not(.hidden)').length === 0) document.body.classList.remove('modal-open');
  }
  function setAuthAction(action) {
    state.authAction = action;
    $$('.auth-action').forEach(b => { const active = b.dataset.authAction === action; b.classList.toggle('active',active); b.setAttribute('aria-selected',String(active)); });
    updateAuthForm();
  }
  function setAuthRole(role) {
    state.authRole = role;
    $$('.auth-tab').forEach(b => { const active = b.dataset.authTab === role; b.classList.toggle('active',active); b.setAttribute('aria-selected',String(active)); });
    updateAuthForm();
  }
  function updateAuthForm() {
    const login = $('#login-form');
    const musician = $('#musician-register-form');
    const employer = $('#employer-register-form');
    [login,musician,employer].forEach(f => f?.classList.add('hidden'));
    $('#forgot-password')?.classList.toggle('hidden', state.authAction !== 'login');
    if (state.authAction === 'login') {
      login?.classList.remove('hidden');
      const identity = $('#login-identity');
      const secret = $('#login-secret');
      const label = $('#login-identity-label span');
      const secretLabel = $('#login-secret-label span');
      if (state.authRole === 'employer') {
        label.textContent = 'Registered email address'; identity.type = 'email'; identity.placeholder = 'you@example.com';
        secretLabel.textContent = 'Password'; secret.type = 'password'; secret.removeAttribute('pattern'); secret.removeAttribute('maxlength'); secret.placeholder = 'Your account password';
      } else if (state.authRole === 'admin') {
        label.textContent = 'Registered NIN, email or phone'; identity.type = 'text'; identity.placeholder = 'Your registered identifier';
        secretLabel.textContent = 'Administrator password'; secret.type = 'password'; secret.removeAttribute('pattern'); secret.removeAttribute('maxlength'); secret.placeholder = 'Your account password';
      } else {
        label.textContent = 'Registered NIN, email or phone'; identity.type = 'text'; identity.placeholder = 'Your registered identifier';
        secretLabel.textContent = '4-digit login PIN'; secret.type = 'password'; secret.setAttribute('pattern','[0-9]{4}'); secret.setAttribute('maxlength','4'); secret.placeholder = '••••';
      }
    } else if (state.authRole === 'employer') {
      employer?.classList.remove('hidden');
    } else if (state.authRole === 'musician') {
      musician?.classList.remove('hidden');
    } else {
      // Admin accounts are invitation-only. Never expose an admin sign-up form.
      login?.classList.remove('hidden');
      setTimeout(() => showToast('Admin access is invitation-only','An owner must authorise and provision administrator access. This demo cannot create admin accounts.'),0);
      setAuthAction('login');
    }
    const title = $('#auth-modal-title');
    if (title) title.textContent = state.authAction === 'login' ? 'Welcome back.' : state.authRole === 'employer' ? 'Start hiring talent.' : 'Your music journey starts here.';
    $('#auth-modal-description').textContent = state.authAction === 'login' ? 'Choose your role and enter your registered details.' : 'Use the registration path that matches your role.';
  }
  function openAuth(action='login', role='musician') {
    setAuthRole(role);
    setAuthAction(action);
    modalOpen($('#auth-modal'));
    window.setTimeout(() => $('#auth-modal .auth-form:not(.hidden) input:not([type=\"file\"])')?.focus(),70);
  }

  function openGig(id) {
    const gig = gigs.find(item => item.id === Number(id));
    if (!gig) return;
    state.activeGig = gig;
    $('#gig-modal-title').textContent = gig.title;
    $('#gig-modal-content').innerHTML = `
      <span class="gig-detail-label">${safe(gig.specialty)} · sample listing</span>
      <p class="gig-detail-description">${safe(gig.description)}</p>
      <div class="gig-detail-grid">
        <div class="gig-detail-cell"><span>Gig payment</span><strong>${money(gig.pay)}</strong></div>
        <div class="gig-detail-cell"><span>Separate reserve</span><strong>₦1,000</strong></div>
        <div class="gig-detail-cell"><span>Location</span><strong>${safe(gig.location)}</strong></div>
        <div class="gig-detail-cell"><span>Date & time</span><strong>${safe(gig.dateLabel)}<br>${safe(gig.start)}–${safe(gig.end)}</strong></div>
        <div class="gig-detail-cell"><span>Specialty match</span><strong>${safe(gig.specialty)}</strong></div>
        <div class="gig-detail-cell"><span>Poster</span><strong>${safe(gig.poster)}</strong></div>
      </div>
      <p class="gig-detail-description"><strong>Before applying:</strong> check that the time does not clash with an accepted booking. In production, the backend must confirm availability atomically and the employer must fund the gig before it goes live.</p>`;
    modalOpen($('#gig-modal'));
  }

  document.addEventListener('click', event => {
    const authButton = event.target.closest('[data-open-auth]');
    if (authButton) {
      event.preventDefault();
      openAuth(authButton.dataset.openAuth, authButton.dataset.authRole || 'musician');
      $('#primary-nav')?.classList.remove('open');
      $('#mobile-menu-button')?.setAttribute('aria-expanded','false');
      return;
    }
    const postGigButton = event.target.closest('[data-open-post-gig]');
    if (postGigButton) {
      event.preventDefault();
      modalOpen($('#post-gig-modal'));
      $('#primary-nav')?.classList.remove('open');
      $('#mobile-menu-button')?.setAttribute('aria-expanded','false');
      return;
    }
    const detail = event.target.closest('[data-gig-details]');
    if (detail) { openGig(detail.dataset.gigDetails); return; }
    const authTab = event.target.closest('[data-auth-tab]');
    if (authTab) { setAuthRole(authTab.dataset.authTab); return; }
    const actionTab = event.target.closest('[data-auth-action]');
    if (actionTab) { setAuthAction(actionTab.dataset.authAction); return; }
  });
  $('#close-auth')?.addEventListener('click', () => modalClose($('#auth-modal')));
  $('#close-gig')?.addEventListener('click', () => modalClose($('#gig-modal')));
  $('#close-post-gig')?.addEventListener('click', () => modalClose($('#post-gig-modal')));
  $$('.modal-backdrop').forEach(backdrop => backdrop.addEventListener('click', e => { if (e.target === backdrop) modalClose(backdrop); }));
  document.addEventListener('keydown', e => { if (e.key === 'Escape') $$('.modal-backdrop:not(.hidden)').forEach(modalClose); });
  $('#mobile-menu-button')?.addEventListener('click', () => {
    const nav = $('#primary-nav'); const open = nav.classList.toggle('open');
    $('#mobile-menu-button').setAttribute('aria-expanded',String(open));
  });
  $$('#primary-nav a').forEach(link => link.addEventListener('click', () => { $('#primary-nav').classList.remove('open'); $('#mobile-menu-button').setAttribute('aria-expanded','false'); }));

  $('#gig-search-form')?.addEventListener('submit', event => { event.preventDefault(); renderGigs(); $('#gigs').scrollIntoView({behavior:'smooth'}); });
  $('#sort-gigs')?.addEventListener('change', renderGigs);
  $('#clear-filters')?.addEventListener('click', () => { $('#specialty-filter').value=''; $('#location-filter').value=''; $('#sort-gigs').value='recommended'; renderGigs(); });
  $('#forgot-password')?.addEventListener('click', () => showToast('Password recovery is a backend feature','A real deployment should send a secure recovery email. Preview mode does not send emails or reveal login details.'));

  const previewSubmit = (form, title, detail) => form?.addEventListener('submit', async event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    if (config.DEMO_MODE || !config.API_BASE_URL) {
      showToast(title, detail || 'Preview mode is active. Nothing was sent, uploaded, or stored. Do not enter real personal or banking information.');
      form.reset();
      return;
    }
    showToast('Backend connection not configured','This front-end starter has no production API submit handler. Follow the backend integration checklist before enabling registration.');
  });
  previewSubmit($('#login-form'),'Secure login is not active','This is a visual preview. No credentials were checked or stored.');
  previewSubmit($('#musician-register-form'),'Registration is preview-only','No NIN, video, contact, PIN or bank details were sent or saved. Do not submit real data here.');
  previewSubmit($('#employer-register-form'),'Email verification is not active','No account was created and no OTP email was sent. Connect the secure authentication backend first.');

  $('#post-gig-form')?.addEventListener('submit', event => {
    event.preventDefault();
    const form = event.currentTarget;
    const startInput = form.elements.startsAt;
    const endInput = form.elements.endsAt;
    startInput.setCustomValidity(''); endInput.setCustomValidity('');
    form.elements.payment.setCustomValidity('');
    if (!form.reportValidity()) return;
    const data = new FormData(form);
    const start = new Date(String(data.get('startsAt')));
    const end = new Date(String(data.get('endsAt')));
    if (start <= new Date()) { startInput.setCustomValidity('Choose a future start time.'); startInput.reportValidity(); return; }
    if (!(end > start)) { endInput.setCustomValidity('The ending time must be after the starting time.'); endInput.reportValidity(); return; }
    const pay = Number(data.get('payment'));
    if (!Number.isFinite(pay) || pay < 2000) { form.elements.payment.setCustomValidity('The minimum gig amount is ₦2,000.'); form.elements.payment.reportValidity(); return; }
    const result = $('#post-gig-preview-result');
    result.innerHTML = `<div class="gig-detail-grid"><div class="gig-detail-cell"><span>Gig title</span><strong>${safe(data.get('title'))}</strong></div><div class="gig-detail-cell"><span>Specialty</span><strong>${safe(data.get('specialty'))}</strong></div><div class="gig-detail-cell"><span>Payment</span><strong>${money(pay)}</strong></div><div class="gig-detail-cell"><span>Penalty reserve</span><strong>₦1,000</strong></div><div class="gig-detail-cell"><span>Location</span><strong>${safe(data.get('venue'))}, ${safe(data.get('city'))}</strong></div><div class="gig-detail-cell"><span>GPS coordinates</span><strong>${safe(data.get('latitude'))}, ${safe(data.get('longitude'))}</strong></div><div class="gig-detail-cell"><span>Starts</span><strong>${safe(start.toLocaleString())}</strong></div><div class="gig-detail-cell"><span>Ends</span><strong>${safe(end.toLocaleString())}</strong></div></div><p class="gig-detail-description"><strong>Preview only:</strong> this request has not been saved, paid for or published. A live platform must charge and verify payment before publishing and calculate the platform fee at checkout.</p>`;
    result.classList.remove('hidden');
    showToast('Gig preview generated','Nothing was sent to a server or saved. This is not a live job listing.');
  });
  $('#post-gig-form')?.querySelectorAll('input').forEach(input => input.addEventListener('input', () => input.setCustomValidity('')));
  $('#post-gig-form')?.elements?.payment?.addEventListener('input', event => event.currentTarget.setCustomValidity(''));

  $('#gig-modal-apply')?.addEventListener('click', () => { modalClose($('#gig-modal')); openAuth('login','musician'); showToast('Applications are not live','This example gig is not a real vacancy and no application has been submitted.'); });

  // Client-side video metadata check is an early usability hint only; the server must validate uploads.
  const videoInput = $('#musician-register-form input[name="skillVideo"]');
  videoInput?.addEventListener('change', () => {
    const file = videoInput.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('video/')) { videoInput.setCustomValidity('Choose a video file.'); videoInput.reportValidity(); return; }
    videoInput.setCustomValidity('');
    const objectUrl = URL.createObjectURL(file);
    const video = document.createElement('video'); video.preload = 'metadata'; video.src = objectUrl;
    video.onloadedmetadata = () => {
      URL.revokeObjectURL(objectUrl);
      if (Number.isFinite(video.duration) && video.duration < 60) {
        videoInput.setCustomValidity('The video should be at least 60 seconds long.');
        videoInput.reportValidity();
      } else {
        videoInput.setCustomValidity('');
        showToast('Video length looks acceptable','This local preview checks duration only. It does not upload or verify your skill video.');
      }
    };
    video.onerror = () => { URL.revokeObjectURL(objectUrl); videoInput.setCustomValidity('The selected video duration could not be read.'); videoInput.reportValidity(); };
  });

  const year = $('#current-year'); if (year) year.textContent = String(new Date().getFullYear());
  renderGigs();
})();
