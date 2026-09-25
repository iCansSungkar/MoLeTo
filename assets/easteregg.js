/*
    SNAKEASS.js 
    Copyright (c) <2026, 2027> Ihsan Sungkar
    Modifikasi: pointer/kapal diganti ULAR.
    - Ular memakan TEKS (elemen teks dimakan -> ular memanjang + poin)
    - Ular MATI jika menabrak gambar, tombol, form, iframe, ikon SVG,
      atau "shape" (elemen dengan background/border)
    - Ular MATI jika menabrak badan sendiri
    - Panah/WASD = belok, SPASI = main lagi, ESC = keluar
*/
(function(window) {

    /* ================= Class (dari KickAss.js) ================= */
    var Class = function(methods) {
        var ret = function() {
            if (ret.$prototyping) return this;
            if (typeof this.initialize == 'function')
                return this.initialize.apply(this, arguments);
        };
        if (methods.Extends) {
            ret.parent = methods.Extends;
            methods.Extends.$prototyping = true;
            ret.prototype = new methods.Extends;
            methods.Extends.$prototyping = false;
        }
        for (var key in methods)
            if (methods.hasOwnProperty(key))
                ret.prototype[key] = methods[key];
        return ret;
    };

    /* ================= Vector (dari KickAss.js) ================= */
    var Vector = new Class({
        initialize: function(x, y) {
            if (typeof x == 'object') { this.x = x.x; this.y = x.y; }
            else { this.x = x; this.y = y; }
        },
        cp: function() { return new Vector(this.x, this.y); },
        mul: function(f) { this.x *= f; this.y *= f; return this; },
        mulNew: function(f) { return new Vector(this.x * f, this.y * f); },
        add: function(v) { this.x += v.x; this.y += v.y; return this; },
        addNew: function(v) { return new Vector(this.x + v.x, this.y + v.y); },
        subNew: function(v) { return new Vector(this.x - v.x, this.y - v.y); },
        setLength: function(l) { var len = this.len(); if (len) this.mul(l / len); else { this.x = this.y = l; } return this; },
        normalize: function() { var l = this.len(); if (l == 0) return this; this.x /= l; this.y /= l; return this; },
        angle: function() { return Math.atan2(this.y, this.x); },
        len: function() { var l = Math.sqrt(this.x * this.x + this.y * this.y); if (l < 0.005 && l > -0.005) return 0; return l; },
        is: function(t) { return typeof t == 'object' && this.x == t.x && this.y == t.y; }
    });

    /* ================= Utils ================= */
    function now() { return (new Date()).getTime(); }
    function bind(bound, func) { return function() { return func.apply(bound, arguments); }; }
    function random(min, max) { return Math.floor(Math.random() * (max - min + 1) + min); }
    function addEvent(obj, type, fn) { if (obj.addEventListener) obj.addEventListener(type, fn, false); else if (obj.attachEvent) obj.attachEvent('on' + type, fn); }
    function removeEvent(obj, type, fn) { if (obj.removeEventListener) obj.removeEventListener(type, fn, false); else if (obj.detachEvent) obj.detachEvent('on' + type, fn); }
    function stopEvent(e) { if (e.stopPropagation) e.stopPropagation(); if (e.preventDefault) e.preventDefault(); e.returnValue = false; }
    function getGlobalNamespace() { return window && window.INSTALL_SCOPE ? window.INSTALL_SCOPE : window; }
    function escapeHTML(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

    /* ================= Konfigurasi game ================= */
    var G = {
        FPS: 60,
        zIndex: 2147483000,
        startSegments: 8,		// panjang awal ular
        maxSegments: 70,		// panjang maksimal
        segmentSpacing: 9,		// jarak antar ruas badan (px)
        bodyRadius: 7,			// radius ruas badan
        headRadius: 9,			// radius kepala
        baseSpeed: 140,			// kecepatan awal (px/detik)
        maxSpeedBonus: 90,		// bonus kecepatan maksimal
        graceTime: 1.0			// detik kebal setelah spawn (kedip-kedip)
    };

    /* ================= CSS UI ================= */
    function injectCSS() {
        var css = [
            '#snakeass-score{position:fixed;top:12px;right:12px;z-index:2147483000;background:rgba(17,17,17,.82);color:#fff;',
            'font:bold 13px/1 Arial,Helvetica,sans-serif;padding:10px 16px;border-radius:999px;letter-spacing:.5px;',
            'pointer-events:none;box-shadow:0 2px 10px rgba(0,0,0,.35)}',
            '#snakeass-score b{color:#7CFC00}',
            '#snakeass-msg{position:fixed;top:14px;left:50%;transform:translateX(-50%);z-index:2147483000;',
            'background:rgba(17,17,17,.82);color:#fff;font:bold 14px/1.4 Arial,Helvetica,sans-serif;padding:10px 18px;',
            'border-radius:10px;pointer-events:none;text-align:center;max-width:80vw;transition:opacity .4s;opacity:0}',
            '.snakeass-bubble{position:absolute;z-index:2147483000;color:#7CFC00;font:bold 16px Arial,sans-serif;',
            'text-shadow:0 1px 2px rgba(0,0,0,.8);pointer-events:none;white-space:nowrap;',
            'transform:translate(-50%,-50%);animation:snakeassFloat .9s ease-out forwards}',
            '@keyframes snakeassFloat{0%{opacity:1;margin-top:0}100%{opacity:0;margin-top:-34px}}',
            '#snakeass-over{position:fixed;left:0;top:0;right:0;bottom:0;z-index:2147483001;display:flex;',
            'align-items:center;justify-content:center;background:rgba(0,0,0,.55);cursor:pointer}',
            '#snakeass-over .snakeass-box{background:#111;color:#fff;border:2px solid #7CFC00;border-radius:14px;',
            'padding:28px 40px;text-align:center;font-family:Arial,Helvetica,sans-serif;box-shadow:0 10px 40px rgba(0,0,0,.6)}',
            '#snakeass-over h1{margin:0 0 10px;font-size:34px;color:#ff4136;letter-spacing:2px}',
            '#snakeass-over .snakeass-cause{color:#ffb700;font-size:15px;margin-bottom:10px}',
            '#snakeass-over .snakeass-score{font-size:18px;margin-bottom:14px}',
            '#snakeass-over .snakeass-score b{color:#7CFC00;font-size:24px}',
            '#snakeass-over .snakeass-hint{color:#bbb;font-size:13px;animation:snakeassBlink 1.2s infinite}',
            '@keyframes snakeassBlink{0%,100%{opacity:1}50%{opacity:.25}}'
        ].join('');
        var style = document.createElement('style');
        style.id = 'snakeass-style';
        style.textContent = css;
        (document.head || document.body).appendChild(style);
    }

    /* ================= Efek suara kecil (WebAudio, tanpa file) ================= */
    var Sfx = new Class({
        initialize: function() { this.ctx = null; },
        ensure: function() {
            if (this.ctx) {
                if (this.ctx.state == 'suspended') { try { this.ctx.resume(); } catch (e) {} }
                return;
            }
            try {
                var AC = window.AudioContext || window.webkitAudioContext;
                if (AC) this.ctx = new AC();
            } catch (e) {}
        },
        tone: function(freq, freqEnd, duration, type, volume) {
            if (!this.ctx) return;
            try {
                var t = this.ctx.currentTime;
                var osc = this.ctx.createOscillator();
                var gain = this.ctx.createGain();
                osc.type = type || 'square';
                osc.frequency.setValueAtTime(freq, t);
                if (freqEnd) osc.frequency.exponentialRampToValueAtTime(Math.max(1, freqEnd), t + duration);
                gain.gain.setValueAtTime(volume || 0.07, t);
                gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
                osc.connect(gain); gain.connect(this.ctx.destination);
                osc.start(t); osc.stop(t + duration + 0.02);
            } catch (e) {}
        },
        eat: function(n) { this.ensure(); this.tone(420 + (n % 6) * 60, 840, 0.09, 'square', 0.05); },
        die: function() { this.ensure(); this.tone(300, 55, 0.6, 'sawtooth', 0.08); }
    });

    /* ================= Kanvas pembantu (gaya Sheet di KickAss.js) ================= */
    var GameCanvas = new Class({
        initialize: function(x, y, w, h) {
            this.canvas = document.createElement('canvas');
            this.canvas.className = 'KICKASSELEMENT SNAKEASSELEMENT';
            var s = this.canvas.style;
            s.position = 'absolute';
            s.zIndex = G.zIndex;
            s.pointerEvents = 'none'; // penting: agar tidak tertangkap elementFromPoint
            this.canvas.width = Math.max(1, Math.round(w));
            this.canvas.height = Math.max(1, Math.round(h));
            this.ctx = this.canvas.getContext('2d');
            document.body.appendChild(this.canvas);
            this.place(x, y, w, h);
        },
        place: function(x, y, w, h) {
            x = Math.round(x); y = Math.round(y);
            w = Math.max(1, Math.round(w)); h = Math.max(1, Math.round(h));
            this.canvas.style.left = x + 'px';
            this.canvas.style.top = y + 'px';
            if (this.canvas.width !== w) this.canvas.width = w;
            if (this.canvas.height !== h) this.canvas.height = h;
        },
        clear: function() { this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height); },
        destroy: function() { if (this.canvas.parentNode) this.canvas.parentNode.removeChild(this.canvas); }
    });

    /* ================= Klasifikasi elemen halaman =================
       'solid'   = mematikan (gambar, tombol, form, iframe, svg, kotak berlatar/border)
       'food'    = bisa dimakan (elemen berisi teks langsung)
       'food-bg' = wadah raksasa (latar halaman) yang punya teks -> teksnya dimakan saja
       null      = dilewati (elemen transparan tanpa teks)                          */
    var SOLID_TAGS = { IMG:1, PICTURE:1, CANVAS:1, VIDEO:1, AUDIO:1, IFRAME:1, FRAME:1, OBJECT:1, EMBED:1, APPLET:1, BUTTON:1, INPUT:1, SELECT:1, TEXTAREA:1, METER:1, PROGRESS:1, HR:1, MAP:1 };
    var SKIP_TAGS = { SCRIPT:1, STYLE:1, HEAD:1, META:1, LINK:1, TITLE:1, NOSCRIPT:1, TEMPLATE:1, BR:1, WBR:1, BASE:1, COL:1, COLGROUP:1, PARAM:1, SOURCE:1, TRACK:1, AREA:1, OPTION:1, OPTGROUP:1, DATALIST:1 };

    function tagName(el) { return (el.tagName || '').toUpperCase(); }
    function isSvg(el) { return !!el.ownerSVGElement || tagName(el) == 'SVG'; }

    function hasDirectText(el) {
        var nodes = el.childNodes;
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i];
            if (n.nodeType === 3 && n.nodeValue && /\S/.test(n.nodeValue)) return true;
        }
        return false;
    }

    function directText(el) {
        var out = '', nodes = el.childNodes;
        for (var i = 0; i < nodes.length; i++)
            if (nodes[i].nodeType === 3) out += nodes[i].nodeValue;
        return out.replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
    }

    function colorAlpha(c) {
        if (!c) return 0;
        c = String(c).replace(/\s/g, '').toLowerCase();
        if (c == 'transparent' || c == 'rgba(0,0,0,0)') return 0;
        var m = c.match(/^rgba?\(([^)]+)\)$/);
        if (m) {
            var p = m[1].split(',');
            return p.length > 3 ? parseFloat(p[3]) : 1;
        }
        return 1;
    }

    function solidByStyle(style) {
        if (colorAlpha(style.backgroundColor) > 0) return true;
        if (style.backgroundImage && style.backgroundImage != 'none') return true;
        var sides = ['Top', 'Right', 'Bottom', 'Left'];
        for (var i = 0; i < 4; i++) {
            var w = parseFloat(style['border' + sides[i] + 'Width']);
            var st = style['border' + sides[i] + 'Style'];
            if (w >= 1 && st && st != 'none' && st != 'hidden') return true;
        }
        return false;
    }

    // elemen "raksasa" dianggap latar halaman -> bukan rintangan
    function isHuge(rect, vw, vh) {
        if (rect.width >= vw * 0.6 && rect.height >= vh * 0.6) return true;
        if (rect.width * rect.height >= vw * vh * 0.4) return true;
        return false;
    }

    function solidLabel(tag) {
        switch (tag) {
            case 'IMG': case 'PICTURE': return 'gambar';
            case 'BUTTON': return 'tombol';
            case 'INPUT': case 'SELECT': case 'TEXTAREA': return 'kolom form';
            case 'IFRAME': case 'FRAME': case 'OBJECT': case 'EMBED': return 'frame';
            case 'VIDEO': case 'CANVAS': case 'AUDIO': return 'media';
            case 'HR': return 'garis';
            default: return 'elemen <' + tag.toLowerCase() + '>';
        }
    }

    function classifyElement(el, vw, vh) {
        if (!el || el.nodeType !== 1) return null;
        var tag = tagName(el);
        if (SKIP_TAGS[tag]) return null;
        if (typeof el.className == 'string' && el.className.indexOf('KICKASSELEMENT') != -1) return null;
        if (el == document.documentElement || el == document.body) {
            // body/html tidak boleh jadi rintangan; teksnya saja yang bisa dimakan
            return hasDirectText(el) ? { type: 'food-bg', el: el, label: 'teks latar' } : null;
        }
        if (isSvg(el)) return { type: 'solid', el: el, label: 'ikon SVG' };
        if (SOLID_TAGS[tag]) return { type: 'solid', el: el, label: solidLabel(tag) };
        var style;
        try { style = window.getComputedStyle(el); } catch (e) { return null; }
        if (!style || style.visibility == 'hidden' || style.display == 'none') return null;
        var rect = el.getBoundingClientRect();
        if (rect.width < 2 || rect.height < 2) return null;
        var text = hasDirectText(el);
        if (isHuge(rect, vw, vh)) {
            return text ? { type: 'food-bg', el: el, label: 'teks latar' } : null;
        }
        if (solidByStyle(style)) {
            return { type: 'solid', el: el, label: SOLID_TAGS[tag] ? solidLabel(tag) : 'kotak <' + tag.toLowerCase() + '>' };
        }
        if (text) return { type: 'food', el: el, label: 'teks' };
        return null;
    }

    function classifyPoint(x, y, vw, vh) {
        var cx = x - (window.pageXOffset || 0);
        var cy = y - (window.pageYOffset || 0);
        var el = null;
        try { el = document.elementFromPoint(cx, cy); } catch (e) { return null; }
        if (!el || el.nodeType !== 1) return null;
        return classifyElement(el, vw, vh);
    }

    /* ================= Ledakan partikel ================= */
    var Explosion = new Class({
        initialize: function(pos, big) {
            this.bornAt = now();
            this.ttl = big ? 1000 : 550;
            this.big = big;
            this.size = big ? 420 : 200;
            this.particles = [];
            var count = big ? 46 : 16;
            var colors = big ? ['#ff4136', '#ff851b', '#ffdc00', '#7CFC00'] : ['#7CFC00', '#2ECC40', '#ffdc00'];
            for (var i = 0; i < count; i++) {
                var d = new Vector(random(-100, 100), random(-100, 100));
                if (d.len() < 0.001) d = new Vector(1, 0);
                d.normalize();
                this.particles.push({
                    dir: d,
                    vel: random(big ? 60 : 40, big ? 280 : 170),
                    pos: new Vector(0, 0),
                    color: colors[random(0, colors.length - 1)]
                });
            }
            this.canvas = new GameCanvas(pos.x - this.size / 2, pos.y - this.size / 2, this.size, this.size);
        },
        update: function(tdelta) {
            this.canvas.clear();
            var ctx = this.canvas.ctx;
            var half = this.size / 2;
            var s = this.big ? 4 : 3;
            for (var i = 0, p; p = this.particles[i]; i++) {
                p.pos.add(p.dir.mulNew(p.vel * tdelta));
                p.vel *= Math.max(0, 1 - 1.6 * tdelta);
                ctx.fillStyle = p.color;
                ctx.fillRect(half + p.pos.x, half + p.pos.y, s, s);
            }
        },
        destroy: function() { this.canvas.destroy(); }
    });

    var ExplosionManager = new Class({
        initialize: function(game) { this.game = game; this.explosions = []; },
        update: function(tdelta) {
            var t = now();
            for (var i = this.explosions.length - 1; i >= 0; i--) {
                var ex = this.explosions[i];
                if (t - ex.bornAt > ex.ttl) { ex.destroy(); this.explosions.splice(i, 1); continue; }
                ex.update(tdelta);
            }
        },
        addExplosion: function(pos, big) { this.explosions.push(new Explosion(pos, big)); },
        destroy: function() {
            for (var i = 0; i < this.explosions.length; i++) this.explosions[i].destroy();
            this.explosions = [];
        }
    });

    /* ================= ULAR ================= */
    var Snake = new Class({
        initialize: function(game) {
            this.game = game;
            this.canvas = new GameCanvas(0, 0, 10, 10);
            this.reset();
        },
        reset: function() {
            var w = this.game.windowSize.width, h = this.game.windowSize.height;
            this.pos = new Vector(this.game.scrollPos.x + w / 2, this.game.scrollPos.y + h / 2);
            this.dir = new Vector(1, 0);
            this.length = G.startSegments;
            this.targetLength = G.startSegments;
            this.eaten = 0;
            this.totalDist = 0;
            this.path = [{ x: this.pos.x, y: this.pos.y, d: 0 }];
            this.dead = false;
            this.hidden = false;
            this.grace = G.graceTime;
            this.render();
        },
        setDirection: function(d) {
            if (this.dead || this.hidden) return;
            if (d.x == -this.dir.x && d.y == -this.dir.y) return; // dilarang balik arah
            if (d.x == this.dir.x && d.y == this.dir.y) return;
            this.dir = new Vector(d.x, d.y);
        },
        speed: function() { return G.baseSpeed + Math.min(G.maxSpeedBonus, this.eaten * 2); },
        update: function(tdelta) {
            if (this.dead || this.hidden) return;
            if (this.grace > 0) this.grace -= tdelta;
            if (this.length < this.targetLength)
                this.length = Math.min(this.targetLength, this.length + tdelta * 14);
            var step = this.speed() * tdelta;
            this.pos.x += this.dir.x * step;
            this.pos.y += this.dir.y * step;
            this.wrap();
            this.totalDist += step;
            this.path.push({ x: this.pos.x, y: this.pos.y, d: this.totalDist });
            this.trimPath();
            if (this.grace <= 0) {
                this.checkWorld();
                if (!this.dead) this.checkSelf();
            }
            if (!this.dead) this.render();
        },
        wrap: function() { // arena = viewport saat ini; menembus tepi -> muncul di sisi lain
            var sx = this.game.scrollPos.x, sy = this.game.scrollPos.y;
            var w = this.game.windowSize.width, h = this.game.windowSize.height;
            var r = G.headRadius;
            if (this.pos.x > sx + w + r) this.pos.x = sx - r;
            else if (this.pos.x < sx - r) this.pos.x = sx + w + r;
            if (this.pos.y > sy + h + r) this.pos.y = sy - r;
            else if (this.pos.y < sy - r) this.pos.y = sy + h + r;
        },
        trimPath: function() {
            var need = (this.length - 1) * G.segmentSpacing + 80;
            var p = this.path;
            while (p.length > 2 && (this.totalDist - p[1].d) > need) p.shift();
        },
        samplePath: function(d) { // titik pada jarak d di belakang kepala (badan mengikuti jejak kepala)
            var p = this.path;
            if (d <= p[0].d) return { x: p[0].x, y: p[0].y };
            for (var i = p.length - 1; i > 0; i--) {
                var a = p[i - 1], b = p[i];
                if (a.d <= d && d <= b.d) {
                    var dx = b.x - a.x, dy = b.y - a.y;
                    if (dx * dx + dy * dy > 1600) { // lompatan wrap-around
                        return (d - a.d) > (b.d - d) ? { x: b.x, y: b.y } : { x: a.x, y: a.y };
                    }
                    var t = (d - a.d) / (b.d - a.d);
                    return { x: a.x + dx * t, y: a.y + dy * t };
                }
            }
            var last = p[p.length - 1];
            return { x: last.x, y: last.y };
        },
        checkWorld: function() {
            var hit = classifyPoint(this.pos.x, this.pos.y, this.game.windowSize.width, this.game.windowSize.height);
            if (!hit) return;
            if (hit.type == 'solid') { this.game.snakeDied(hit.label); return; }
            if (hit.type == 'food') { this.game.snakeAte(hit.el, false); return; }
            if (hit.type == 'food-bg') { this.game.snakeAte(hit.el, true); return; }
        },
        checkSelf: function() {
            var n = Math.floor(this.length);
            var minDist = G.headRadius + G.bodyRadius - 2;
            for (var i = 4; i < n; i++) { // lewati 4 ruas pertama (leher)
                var pt = this.samplePath(this.totalDist - i * G.segmentSpacing);
                var dx = pt.x - this.pos.x, dy = pt.y - this.pos.y;
                if (dx * dx + dy * dy < minDist * minDist) {
                    this.game.snakeDied('badan sendiri');
                    return;
                }
            }
        },
        hide: function() { this.hidden = true; this.canvas.clear(); },
        render: function() {
            var n = Math.floor(this.length);
            if (n < 1) n = 1;
            var i;
            var pts = [], radii = [];
            for (i = n - 1; i >= 1; i--)
                pts.push(this.samplePath(this.totalDist - i * G.segmentSpacing));
            var r = G.bodyRadius, hr = G.headRadius;
            var minX = this.pos.x - hr - 8, maxX = this.pos.x + hr + 8;
            var minY = this.pos.y - hr - 8, maxY = this.pos.y + hr + 8;
            for (i = 0; i < pts.length; i++) {
                var t = pts.length > 1 ? i / (pts.length - 1) : 1;
                var rr = r * (1 - 0.45 * t); // makin ke ekor makin kecil
                radii.push(rr);
                if (pts[i].x - rr < minX) minX = pts[i].x - rr;
                if (pts[i].x + rr > maxX) maxX = pts[i].x + rr;
                if (pts[i].y - rr < minY) minY = pts[i].y - rr;
                if (pts[i].y + rr > maxY) maxY = pts[i].y + rr;
            }
            var ox = minX, oy = minY;
            var w = Math.ceil(maxX - minX), h = Math.ceil(maxY - minY);
            this.canvas.place(ox, oy, w, h);
            var ctx = this.canvas.ctx;
            ctx.clearRect(0, 0, w, h);
            ctx.globalAlpha = this.grace > 0 ? 0.35 + 0.35 * Math.abs(Math.sin(now() / 90)) : 1;
            // badan
            for (i = 0; i < pts.length; i++) {
                ctx.beginPath();
                ctx.arc(pts[i].x - ox, pts[i].y - oy, radii[i], 0, Math.PI * 2);
                ctx.fillStyle = (i % 2 == 0) ? '#2ECC40' : '#27AE60';
                ctx.fill();
                ctx.lineWidth = 1;
                ctx.strokeStyle = 'rgba(0,0,0,0.4)';
                ctx.stroke();
            }
            // kepala
            var hx = this.pos.x - ox, hy = this.pos.y - oy;
            ctx.beginPath();
            ctx.arc(hx, hy, hr, 0, Math.PI * 2);
            ctx.fillStyle = '#2ECC40';
            ctx.fill();
            ctx.lineWidth = 1.5;
            ctx.strokeStyle = 'rgba(0,0,0,0.55)';
            ctx.stroke();
            // lidah
            ctx.beginPath();
            ctx.moveTo(hx + this.dir.x * hr, hy + this.dir.y * hr);
            ctx.lineTo(hx + this.dir.x * (hr + 6), hy + this.dir.y * (hr + 6));
            ctx.strokeStyle = '#ff4136';
            ctx.lineWidth = 1.5;
            ctx.stroke();
            // mata
            var px = -this.dir.y, py = this.dir.x;
            for (var s = -1; s <= 1; s += 2) {
                var ex = hx + this.dir.x * 3.5 + px * 4.5 * s;
                var ey = hy + this.dir.y * 3.5 + py * 4.5 * s;
                ctx.beginPath(); ctx.arc(ex, ey, 2.7, 0, Math.PI * 2); ctx.fillStyle = '#fff'; ctx.fill();
                ctx.beginPath(); ctx.arc(ex + this.dir.x * 1.1, ey + this.dir.y * 1.1, 1.4, 0, Math.PI * 2); ctx.fillStyle = '#111'; ctx.fill();
            }
            ctx.globalAlpha = 1;
        },
        destroy: function() { this.canvas.destroy(); }
    });

    /* ================= UI (skor, pesan, game over) ================= */
    var UIManager = new Class({
        initialize: function(game) {
            this.game = game;
            this.bubbles = [];
            this._lastScore = '';
            this._msgTimer = null;
            this.scoreEl = document.createElement('div');
            this.scoreEl.id = 'snakeass-score';
            this.scoreEl.className = 'KICKASSELEMENT';
            document.body.appendChild(this.scoreEl);
            this.msgEl = document.createElement('div');
            this.msgEl.id = 'snakeass-msg';
            this.msgEl.className = 'KICKASSELEMENT';
            this.msgEl.style.opacity = 0;
            document.body.appendChild(this.msgEl);
            this.overEl = document.createElement('div');
            this.overEl.id = 'snakeass-over';
            this.overEl.className = 'KICKASSELEMENT';
            this.overEl.style.display = 'none';
            document.body.appendChild(this.overEl);
            addEvent(this.overEl, 'click', bind(game, game.restart));
        },
        updateScore: function() {
            var g = this.game;
            var str = 'SKOR <b>' + g.score + '</b> &nbsp;•&nbsp; TERBAIK <b>' + g.best + '</b> &nbsp;•&nbsp; PANJANG <b>' + Math.floor(g.snake.length) + '</b>';
            if (str != this._lastScore) { this.scoreEl.innerHTML = str; this._lastScore = str; }
        },
        showMessage: function(html, ms) {
            this.msgEl.innerHTML = html;
            this.msgEl.style.opacity = 1;
            if (this._msgTimer) clearTimeout(this._msgTimer);
            this._msgTimer = setTimeout(bind(this, function() { this.msgEl.style.opacity = 0; }), ms || 3500);
        },
        bubble: function(x, y, text) {
            var b = document.createElement('span');
            b.className = 'snakeass-bubble KICKASSELEMENT';
            b.innerHTML = text;
            b.style.left = x + 'px';
            b.style.top = y + 'px';
            document.body.appendChild(b);
            this.bubbles.push(b);
            var self = this;
            setTimeout(function() {
                if (b.parentNode) b.parentNode.removeChild(b);
                var idx = self.bubbles.indexOf(b);
                if (idx != -1) self.bubbles.splice(idx, 1);
            }, 950);
        },
        showGameOver: function(score, best, cause) {
            this.overEl.innerHTML =
                '<div class="snakeass-box">' +
                '<h1>GAME OVER</h1>' +
                '<div class="snakeass-cause">Ular menabrak: <b>' + escapeHTML(cause) + '</b></div>' +
                '<div class="snakeass-score">SKOR <b>' + score + '</b> &nbsp;•&nbsp; TERBAIK <b>' + best + '</b></div>' +
                '<div class="snakeass-hint">Tekan SPASI atau klik untuk main lagi &nbsp;•&nbsp; ESC untuk keluar</div>' +
                '</div>';
            this.overEl.style.display = 'flex';
        },
        hideGameOver: function() { this.overEl.style.display = 'none'; },
        destroy: function() {
            var els = [this.scoreEl, this.msgEl, this.overEl].concat(this.bubbles);
            for (var i = 0; i < els.length; i++)
                if (els[i] && els[i].parentNode) els[i].parentNode.removeChild(els[i]);
        }
    });

    /* ================= Game utama ================= */
    var SnakeGame = new Class({
        initialize: function() {
            this.windowSize = { width: 0, height: 0 };
            this.scrollPos = new Vector(0, 0);
            this.updateWindowInfo();
            injectCSS();
            this.sfx = new Sfx();
            this.explosionManager = new ExplosionManager(this);
            this.snake = new Snake(this);
            this.score = 0;
            this.best = 0;
            try { this.best = parseInt(window.localStorage.getItem('snakeass_best'), 10) || 0; } catch (e) {}
            this._msg200 = false;
            this.ui = new UIManager(this);
            this.state = 'playing';
            this.lastUpdate = now();
            this.keydownEvent = bind(this, this.keydown);
            addEvent(document, 'keydown', this.keydownEvent);
            this.ui.showMessage('🐍 <b>SNAKE</b> — Panah/WASD: bergerak • makan <b>teks</b> • hindari gambar, tombol, kotak &amp; badan sendiri • ESC: keluar', 6500);
            this.ui.updateScore();
            this.loopTimer = window.setInterval(bind(this, this.loop), 1000 / G.FPS);
        },
        updateWindowInfo: function() {
            this.windowSize.width = window.innerWidth || document.documentElement.clientWidth || 800;
            this.windowSize.height = window.innerHeight || document.documentElement.clientHeight || 600;
            this.scrollPos.x = window.pageXOffset || 0;
            this.scrollPos.y = window.pageYOffset || 0;
        },
        keydown: function(e) {
            var t = e.target;
            if (t && (t.tagName == 'INPUT' || t.tagName == 'TEXTAREA' || t.tagName == 'SELECT' || t.isContentEditable)) return;
            if (e.ctrlKey || e.metaKey || e.altKey) return;
            this.sfx.ensure();
            var k = e.keyCode, dir = null;
            if (k == 37 || k == 65) dir = { x: -1, y: 0 };       // kiri / A
            else if (k == 39 || k == 68) dir = { x: 1, y: 0 };   // kanan / D
            else if (k == 38 || k == 87) dir = { x: 0, y: -1 };  // atas / W
            else if (k == 40 || k == 83) dir = { x: 0, y: 1 };   // bawah / S
            else if (k == 27) { stopEvent(e); this.destroy(); return; } // ESC
            else if (k == 32) { stopEvent(e); if (this.state == 'over') this.restart(); return; } // SPASI
            if (dir) {
                stopEvent(e); // cegah halaman ikut scroll
                this.snake.setDirection(dir);
            }
        },
        loop: function() {
            var t = now();
            var tdelta = (t - this.lastUpdate) / 1000;
            this.lastUpdate = t;
            if (tdelta > 0.1) tdelta = 0.1;
            if (tdelta <= 0) tdelta = 0.001;
            this.updateWindowInfo();
            try {
                if (this.state == 'playing') this.snake.update(tdelta);
                this.explosionManager.update(tdelta);
            } catch (err) {
                if (!this._errLogged) { this._errLogged = true; console.error('[SnakeAss]', err); }
            }
            this.ui.updateScore();
        },
        snakeAte: function(el, textOnly) {
            if (!el || el.nodeType !== 1) return
            var text = directText(el);
            var ok = false;
            try {
                if (textOnly) {
                    // wadah raksasa: habiskan hanya node teksnya, biarkan wadahnya
                    var nodes = el.childNodes;
                    for (var i = nodes.length - 1; i >= 0; i--) {
                        if (nodes[i].nodeType === 3 && /\S/.test(nodes[i].nodeValue || '')) {
                            el.removeChild(nodes[i]);
                            ok = true;
                        }
                    }
                } else if (el.parentNode) {
                    el.parentNode.removeChild(el);
                    ok = true;
                }
            } catch (err) { ok = false; }
            if (!ok) return;
            var pts = textOnly ? 5 : Math.max(5, Math.min(50, Math.round(text.length / 3) || 5));
            var growth = textOnly ? 1 : Math.max(2, Math.min(5, Math.round(pts / 8)));
            this.score += pts;
            this.snake.targetLength = Math.min(G.maxSegments, this.snake.targetLength + growth);
            this.snake.eaten++;
            if (this.score > this.best) {
                this.best = this.score;
                try { window.localStorage.setItem('snakeass_best', String(this.best)); } catch (err) {}
            }
            this.sfx.eat(this.snake.eaten);
            this.explosionManager.addExplosion(this.snake.pos.cp(), false);
            var label = '+' + pts;
            var short = text.slice(0, 16);
            if (short) label += ' &quot;' + escapeHTML(short) + (text.length > 16 ? '…' : '') + '&quot;';
            this.ui.bubble(this.snake.pos.x, this.snake.pos.y - 16, label);
            if (this.snake.eaten == 1) this.ui.showMessage('Nyam! Teks pertama dimakan. 🐍', 2200);
            else if (this.snake.eaten == 10) this.ui.showMessage('10 teks dimakan — ular makin panjang &amp; cepat!', 2500);
            else if (this.score >= 200 && !this._msg200) { this._msg200 = true; this.ui.showMessage('200 poin! Ular legendaris. 🏆', 2500); }
        },
        snakeDied: function(cause) {
            if (this.state != 'playing' || this.snake.dead) return;
            this.snake.dead = true;
            this.snake.hide();
            this.sfx.die();
            this.explosionManager.addExplosion(this.snake.pos.cp(), true);
            this.ui.showGameOver(this.score, this.best, cause);
            this.state = 'over';
        },
        restart: function() {
            if (this.state != 'over') return;
            this.ui.hideGameOver();
            this.score = 0;
            this._msg200 = false;
            this.snake.reset();
            this.state = 'playing';
            this.lastUpdate = now();
        },
        destroy: function() {
            removeEvent(document, 'keydown', this.keydownEvent);
            window.clearInterval(this.loopTimer);
            try { this.snake.destroy(); } catch (e) {}
            try { this.explosionManager.destroy(); } catch (e) {}
            try { this.ui.destroy(); } catch (e) {}
            var style = document.getElementById('snakeass-style');
            if (style && style.parentNode) style.parentNode.removeChild(style);
            getGlobalNamespace().KICKASSGAME = false;
        }
    });
    window.SnakeGame = SnakeGame;

    /* ================= Bootstrap ================= */
    var ns = getGlobalNamespace();

    function startSnakeAss() {
        if (!document.body) return;
        if (ns.KICKASSGAME) {
            try { ns.KICKASSGAME.destroy(); } catch (e) {} // klik bookmarklet lagi = matikan
            return;
        }
        ns.KICKASSGAME = new SnakeGame();
    }

    window.startSnakeAss = startSnakeAss;
    startSnakeAss();

})(typeof exports != 'undefined' ? exports : window);
