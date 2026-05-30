/* ============================================
   CryptoLive.space — Main Shared JavaScript
   Navigation, Consent Banner, Analytics, Utilities
   ============================================ */

(function() {
  'use strict';

  // --- Config ---
  const CONFIG = {
    GA4_ID: 'G-5619GV6WJ6',
    CONSENT_KEY: 'cryptolive_consent',
    SCROLL_THRESHOLD: 100,
  };

  // =============================================
  // 1. DOM Ready
  // =============================================
  document.addEventListener('DOMContentLoaded', function() {
    initNavigation();
    initConsentBanner();
    initFAQAccordion();
    initBackToTop();
    initSmoothScroll();
    initCurrentYear();
    initActiveNavLink();
    initScrollAnimations();
  });

  // =============================================
  // 2. Mobile Navigation Toggle
  // =============================================
  function initNavigation() {
    const toggle = document.querySelector('.navbar-toggle');
    const links = document.querySelector('.navbar-links');
    const navbar = document.querySelector('.navbar');

    if (toggle && links) {
      toggle.addEventListener('click', function() {
        const isOpen = links.classList.toggle('open');
        toggle.setAttribute('aria-expanded', isOpen);
      });

      // Close on link click (mobile)
      links.querySelectorAll('a').forEach(function(link) {
        link.addEventListener('click', function() {
          links.classList.remove('open');
          toggle.setAttribute('aria-expanded', 'false');
        });
      });
    }

    // Navbar shadow on scroll
    if (navbar) {
      window.addEventListener('scroll', function() {
        if (window.scrollY > 10) {
          navbar.classList.add('scrolled');
        } else {
          navbar.classList.remove('scrolled');
        }
      }, { passive: true });
    }
  }

  // =============================================
  // 3. Consent Banner (GDPR / CCPA)
  // =============================================
  function initConsentBanner() {
    var consented = localStorage.getItem(CONFIG.CONSENT_KEY);
    if (consented) {
      loadAnalytics();
      return;
    }

    var banner = document.getElementById('consent-banner');
    if (!banner) return;

    // Show with slight delay for better UX
    setTimeout(function() {
      banner.classList.add('show');
    }, 500);

    var acceptBtn = document.getElementById('consent-accept');
    var rejectBtn = document.getElementById('consent-reject');

    if (acceptBtn) {
      acceptBtn.addEventListener('click', function() {
        localStorage.setItem(CONFIG.CONSENT_KEY, 'accepted');
        banner.classList.remove('show');
        loadAnalytics();
        showToast('Preferences saved', 'success');
      });
    }

    if (rejectBtn) {
      rejectBtn.addEventListener('click', function() {
        localStorage.setItem(CONFIG.CONSENT_KEY, 'rejected');
        banner.classList.remove('show');
        showToast('Preferences saved', 'info');
      });
    }
  }

  // =============================================
  // 4. Google Analytics 4
  // =============================================
  function loadAnalytics() {
    // Only load GA if consented
    var consented = localStorage.getItem(CONFIG.CONSENT_KEY);
    if (consented !== 'accepted') return;

    // Update Google Consent Mode — grants ad storage so AdSense can serve
    // personalized ads on all pages (blog, about, faq, etc.)
    // This works even if only the inline gtag stub exists (blog/secondary pages
    // have `function gtag(){dataLayer.push(arguments);}` in the inline script)
    if (window.gtag) {
      gtag('consent', 'update', {
        'analytics_storage': 'granted',
        'ad_storage': 'granted',
        'ad_user_data': 'granted',
        'ad_personalization': 'granted'
      });
    }

    // Check if GA4 script is already in DOM (eagerly loaded on index.html)
    // Use DOM query instead of window.gtag because inline blog scripts define
    // gtag as a dataLayer pusher, making window.gtag always truthy
    if (document.querySelector('script[src*="googletagmanager.com/gtag"]')) return;

    // Load GA4 script
    var script = document.createElement('script');
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + CONFIG.GA4_ID;
    script.async = true;
    document.head.appendChild(script);

    window.dataLayer = window.dataLayer || [];
    window.gtag = function() { dataLayer.push(arguments); };
    gtag('js', new Date());
    gtag('config', CONFIG.GA4_ID, {
      anonymize_ip: true,
      cookie_flags: 'SameSite=None;Secure'
    });

    // Update consent via gtag (ensures ad_storage is granted even on pages
    // where the inline script only set consent to denied, like blog pages)
    gtag('consent', 'update', {
      'analytics_storage': 'granted',
      'ad_storage': 'granted',
      'ad_user_data': 'granted',
      'ad_personalization': 'granted'
    });
  }

  // =============================================
  // 5. FAQ Accordion
  // =============================================
  function initFAQAccordion() {
    var items = document.querySelectorAll('.faq-item');

    items.forEach(function(item) {
      var question = item.querySelector('.faq-question');
      if (!question) return;

      question.addEventListener('click', function() {
        var isOpen = item.classList.contains('open');

        // Close all others
        items.forEach(function(other) {
          other.classList.remove('open');
        });

        // Toggle current
        if (!isOpen) {
          item.classList.add('open');
        }
      });
    });
  }

  // =============================================
  // 6. Back to Top Button
  // =============================================
  function initBackToTop() {
    var btn = document.getElementById('back-to-top');
    if (!btn) return;

    window.addEventListener('scroll', function() {
      if (window.scrollY > CONFIG.SCROLL_THRESHOLD) {
        btn.classList.add('visible');
      } else {
        btn.classList.remove('visible');
      }
    }, { passive: true });

    btn.addEventListener('click', function() {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  // =============================================
  // 7. Smooth Scroll for Anchor Links
  // =============================================
  function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
      anchor.addEventListener('click', function(e) {
        var targetId = this.getAttribute('href');
        if (targetId === '#') return;

        var target = document.querySelector(targetId);
        if (target) {
          e.preventDefault();
          var offset = 80; // navbar height
          var top = target.getBoundingClientRect().top + window.pageYOffset - offset;
          window.scrollTo({ top: top, behavior: 'smooth' });
        }
      });
    });
  }

  // =============================================
  // 8. Current Year in Footer
  // =============================================
  function initCurrentYear() {
    var els = document.querySelectorAll('[data-current-year]');
    if (els.length) {
      var year = new Date().getFullYear();
      els.forEach(function(el) {
        el.textContent = year;
      });
    }
  }

  // =============================================
  // 9. Active Navigation Link
  // =============================================
  function initActiveNavLink() {
    var currentPath = window.location.pathname;
    var links = document.querySelectorAll('.navbar-links a');

    links.forEach(function(link) {
      var href = link.getAttribute('href');
      if (href === currentPath) {
        link.classList.add('active');
      }
    });
  }

  // =============================================
  // 10. Scroll Animations (Intersection Observer)
  // =============================================
  function initScrollAnimations() {
    if (!('IntersectionObserver' in window)) return;

    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

    document.querySelectorAll('.card, .blog-card, .stat-card, .tool-card, .section-header').forEach(function(el) {
      observer.observe(el);
    });
  }

  // =============================================
  // 11. Toast Notification System
  // =============================================
  var toastContainer = null;

  function ensureToastContainer() {
    if (!toastContainer) {
      toastContainer = document.createElement('div');
      toastContainer.className = 'toast-container';
      document.body.appendChild(toastContainer);
    }
    return toastContainer;
  }

  function showToast(message, type) {
    type = type || 'info';
    var container = ensureToastContainer();

    var toast = document.createElement('div');
    toast.className = 'toast toast-' + type;
    toast.textContent = message;

    container.appendChild(toast);

    // Auto remove after 3.5s
    setTimeout(function() {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(function() {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast);
        }
      }, 300);
    }, 3500);
  }

  // Expose globally
  window.showToast = showToast;

  // =============================================
  // 12. Copy to Clipboard Utility
  // =============================================
  window.copyToClipboard = function(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function() {
        showToast('Copied to clipboard!', 'success');
      }).catch(function() {
        fallbackCopy(text);
      });
    } else {
      fallbackCopy(text);
    }
  };

  function fallbackCopy(text) {
    var textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand('copy');
      showToast('Copied to clipboard!', 'success');
    } catch (e) {
      showToast('Failed to copy', 'error');
    }
    document.body.removeChild(textarea);
  }

})();
