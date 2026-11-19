/*
 * The live parts of the Code Locker page:
 * - the segment display (the glowing date on the padlock, and the key counter),
 * - the "lock for" chips in the hero,
 * - the little app window with a ticking code,
 * - the tape of keys that drand makes every 3 seconds.
 * Everything is worked out from the clock. Nothing is fetched.
 */

(() => {
  document.documentElement.classList.add('js');

  const isMotionReduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const $ = (id) => document.getElementById(id);
  const formatNumber = (n) => n.toLocaleString('en-US');

  // MARK: - drand
  // The same chain the app uses ("quicknet"): key no. 1 came out at GENESIS,
  // and a new one comes out every PERIOD seconds.

  const GENESIS = 1692803367;
  const PERIOD = 3;

  /** Where we are on the chain right now, as a fraction. Key n exists once this reaches n. */
  const chainPosition = () => (Date.now() / 1000 - GENESIS) / PERIOD + 1;

  /** The first key that comes out at or after `date`. Matches Drand.round(at:) in the app. */
  const roundAt = (date) => Math.max(0, Math.ceil((date.getTime() / 1000 - GENESIS) / PERIOD)) + 1;

  // MARK: - Segment display
  // A 14-segment display, like the one on the icon. Each segment is a line
  // from (x1, y1) to (x2, y2) in a 10 × 18 box, drawn as a bar with pointed ends.

  const SEGMENTS = {
    a: [1, 0, 9, 0],
    b: [10, 1, 10, 8],
    c: [10, 10, 10, 17],
    d: [1, 18, 9, 18],
    e: [0, 10, 0, 17],
    f: [0, 1, 0, 8],
    g: [1, 9, 4.5, 9],
    h: [5.5, 9, 9, 9],
    i: [1.4, 1.7, 4.1, 7.5],
    j: [5, 1, 5, 8],
    k: [8.6, 1.7, 5.9, 7.5],
    l: [4.1, 10.5, 1.4, 16.3],
    m: [5, 10, 5, 17],
    n: [5.9, 10.5, 8.6, 16.3],
  };

  const GLYPHS = {
    0: 'abcdef', 1: 'bc', 2: 'abghed', 3: 'abcdh', 4: 'fghbc',
    5: 'afghcd', 6: 'afedcgh', 7: 'abc', 8: 'abcdefgh', 9: 'abcdfgh',
    A: 'abcefgh', B: 'abcdjmh', C: 'adef', D: 'abcdjm', E: 'adefgh', F: 'aefg',
    G: 'acdefh', H: 'bcefgh', I: 'adjm', J: 'bcde', K: 'efgkn', L: 'def',
    M: 'bcefik', N: 'bcefin', O: 'abcdef', P: 'abefgh', Q: 'abcdefn',
    R: 'abefghn', S: 'afghcd', T: 'ajm', U: 'bcdef', V: 'eflk', W: 'bcefln',
    X: 'ikln', Y: 'ikm', Z: 'akld', '-': 'gh', ' ': '',
  };

  const CHAR_ADVANCE = 15.5;

  function segmentPoints([x1, y1, x2, y2]) {
    const isDiagonal = x1 !== x2 && y1 !== y2;
    const half = (isDiagonal ? 1.25 : 1.6) / 2;
    const length = Math.hypot(x2 - x1, y2 - y1);
    const ux = (x2 - x1) / length, uy = (y2 - y1) / length;
    const px = -uy * half, py = ux * half;
    const sx = ux * half, sy = uy * half;

    return [
      [x1, y1],
      [x1 + sx + px, y1 + sy + py],
      [x2 - sx + px, y2 - sy + py],
      [x2, y2],
      [x2 - sx - px, y2 - sy - py],
      [x1 + sx - px, y1 + sy - py],
    ].map(([x, y]) => `${x.toFixed(2)},${y.toFixed(2)}`).join(' ');
  }

  const SEGMENT_POINTS = Object.fromEntries(
    Object.entries(SEGMENTS).map(([name, line]) => [name, segmentPoints(line)])
  );

  function renderSegments(element, text) {
    const width = text.length * CHAR_ADVANCE - (CHAR_ADVANCE - 10);

    const chars = [...text].map((char, index) => {
      const lit = GLYPHS[char] ?? '';
      const polygons = Object.entries(SEGMENT_POINTS)
        .map(([name, points]) => `<polygon class="${lit.includes(name) ? 'on' : 'off'}" points="${points}"/>`)
        .join('');
      return `<g transform="translate(${index * CHAR_ADVANCE} 0)">${polygons}</g>`;
    }).join('');

    element.innerHTML =
      `<svg viewBox="-2 -1 ${width + 4} 20" role="img" aria-label="${text}">` +
      `<g transform="skewX(-5) translate(1.6 0)">${chars}</g></svg>`;
  }

  /** Shows `text`, with a short scramble first, like a display working something out. */
  function scrambleTo(element, text) {
    clearInterval(element.scrambleTimer);

    if (isMotionReduced) {
      renderSegments(element, text);
      return;
    }

    const pool = 'ABCDEFGHJKLMNPRSTUXZ0123456789';
    const start = performance.now();

    element.scrambleTimer = setInterval(() => {
      const step = Math.floor((performance.now() - start) / 45);
      const settled = Math.max(0, step - 4);
      const shown = [...text].map((char, index) => {
        if (char === ' ' || index < settled) return char;
        return pool[Math.floor(Math.random() * pool.length)];
      }).join('');

      renderSegments(element, shown);
      if (settled >= text.length) clearInterval(element.scrambleTimer);
    }, 45);
  }

  // MARK: - Hero: the padlock and the chips

  const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  const heroDate = $('hero-date');
  const chips = [...document.querySelectorAll('.chips button')];
  const openingFormat = new Intl.DateTimeFormat('en-US', {
    weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit',
  });
  const dayFormat = new Intl.DateTimeFormat('en-US', { month: 'long', day: 'numeric' });

  let lockDays = 14;

  const openingDate = () => new Date(Date.now() + lockDays * 86_400_000);

  function showOpening() {
    const opening = openingDate();
    const round = roundAt(opening);

    $('hero-opens').textContent = openingFormat.format(opening);
    $('hero-round').textContent = formatNumber(round);
    $('yours-date').textContent = dayFormat.format(opening);
    $('yours-round').textContent = formatNumber(round);
    $('yours-away').textContent = formatNumber(round - Math.floor(chainPosition()));
  }

  function chooseLock(days) {
    lockDays = days;
    chips.forEach((chip) => chip.setAttribute('aria-checked', String(Number(chip.dataset.days) === days)));

    const opening = openingDate();
    const label = `${MONTHS[opening.getMonth()]} ${String(opening.getDate()).padStart(2, '0')}`;
    scrambleTo(heroDate, label);
    showOpening();
  }

  chips.forEach((chip, index) => {
    chip.addEventListener('click', () => chooseLock(Number(chip.dataset.days)));
    chip.addEventListener('keydown', (event) => {
      const move = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[event.key];
      if (!move) return;
      event.preventDefault();
      const next = chips[(index + move + chips.length) % chips.length];
      next.focus();
      next.click();
    });
  });

  chooseLock(lockDays);
  setInterval(showOpening, 1000);

  // MARK: - The app window
  // The codes are made up from the clock, but they change every 30 seconds
  // like real ones, and the ring runs down the same way.

  const CODE_PERIOD = 30;
  const RING_LENGTH = 50.27;

  function fakeCode(seed, step) {
    let x = Math.imul(step ^ (seed * 0x9e3779b1), 0x85ebca6b) >>> 0;
    x ^= x >>> 13;
    x = Math.imul(x, 0xc2b2ae35) >>> 0;
    x = (x ^ (x >>> 16)) >>> 0;
    const digits = String(x % 1_000_000).padStart(6, '0');
    return `${digits.slice(0, 3)} ${digits.slice(3)}`;
  }

  const liveRows = [...document.querySelectorAll('.row[data-live]')];

  function tickCodes() {
    const seconds = Math.floor(Date.now() / 1000);
    const step = Math.floor(seconds / CODE_PERIOD);
    const remaining = CODE_PERIOD - (seconds % CODE_PERIOD);

    liveRows.forEach((row) => {
      row.querySelector('.row-code').textContent = fakeCode(Number(row.dataset.live), step);
      row.querySelector('.ring-fill').style.strokeDashoffset = RING_LENGTH * (1 - remaining / CODE_PERIOD);
      row.querySelector('.ring').classList.toggle('is-ending', remaining <= 5);
    });
  }

  liveRows.forEach((row) => {
    row.addEventListener('click', () => {
      const note = row.querySelector('.row-note');
      note.textContent = 'Copied';
      clearTimeout(row.copiedTimer);
      row.copiedTimer = setTimeout(() => { note.textContent = ''; }, 1500);
    });
  });

  tickCodes();
  setInterval(tickCodes, 1000);

  // MARK: - The tape of keys
  // Keys slide left past the "now" line. Left of the line they exist.
  // Right of it they don't yet.

  const track = $('tape-track');
  const roundNow = $('round-now');
  const CELLS_EACH_SIDE = 12;

  const cells = Array.from({ length: CELLS_EACH_SIDE * 2 + 1 }, () => {
    const cell = document.createElement('div');
    cell.className = 'tape-cell';
    cell.innerHTML = '<i></i><span></span>';
    track.append(cell);
    return cell;
  });

  let newestRound = 0;

  function labelCells() {
    cells.forEach((cell, index) => {
      const round = newestRound + index - CELLS_EACH_SIDE;
      cell.lastChild.textContent = formatNumber(round);
      cell.classList.toggle('lit', round <= newestRound);
      cell.classList.toggle('fresh', round === newestRound);
    });
    renderSegments(roundNow, String(newestRound));
  }

  function moveTape() {
    const position = chainPosition();
    const newest = Math.floor(position);

    if (newest !== newestRound) {
      newestRound = newest;
      labelCells();
    }

    // The newest key sits exactly on the line the moment it comes out, then drifts left.
    const cellWidth = cells[0].offsetWidth;
    const drift = isMotionReduced ? 0 : position - newest;
    track.style.transform = `translateX(${-(CELLS_EACH_SIDE + 0.5 + drift) * cellWidth}px)`;
  }

  let isTapeVisible = true;
  new IntersectionObserver(([entry]) => { isTapeVisible = entry.isIntersecting; }).observe(track.parentElement);

  (function frame() {
    if (isTapeVisible) moveTape();
    requestAnimationFrame(frame);
  })();

  // MARK: - Reveal on scroll

  const revealer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-in');
      revealer.unobserve(entry.target);
    });
  }, { rootMargin: '0px 0px -8% 0px' });

  document.querySelectorAll('.reveal').forEach((element) => revealer.observe(element));
})();
