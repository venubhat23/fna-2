// Modal Fix JavaScript - Add to application.js or admin.js
document.addEventListener('DOMContentLoaded', function() {
  console.log('🔧 Initializing modal fixes...');

  // Fix Bootstrap modal issues
  function initializeModals() {
    // Remove any existing backdrop issues
    document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
      if (!document.querySelector('.modal.show')) {
        backdrop.remove();
      }
    });

    // Initialize all modals
    const modals = document.querySelectorAll('[data-bs-toggle="modal"]');
    modals.forEach(trigger => {
      trigger.addEventListener('click', function(e) {
        e.preventDefault();
        const targetModal = document.querySelector(this.getAttribute('data-bs-target') || this.getAttribute('href'));
        if (targetModal) {
          openModal(targetModal);
        }
      });
    });

    // Custom modal open function
    window.openModal = function(modal) {
      if (typeof modal === 'string') {
        modal = document.querySelector(modal);
      }
      if (modal) {
        modal.style.display = 'block';
        modal.classList.add('show');
        document.body.classList.add('modal-open');

        // Add backdrop if not exists
        if (!document.querySelector('.modal-backdrop')) {
          const backdrop = document.createElement('div');
          backdrop.className = 'modal-backdrop fade show';
          document.body.appendChild(backdrop);
        }
      }
    };

    // Custom modal close function
    window.closeModal = function(modal) {
      if (typeof modal === 'string') {
        modal = document.querySelector(modal);
      }
      if (modal) {
        modal.style.display = 'none';
        modal.classList.remove('show');
        document.body.classList.remove('modal-open');

        // Remove backdrop
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) {
          backdrop.remove();
        }
      }
    };

    // Close modal when clicking outside
    document.addEventListener('click', function(e) {
      if (e.target.classList.contains('modal')) {
        closeModal(e.target);
      }
    });

    // Close modal with escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        const openModal = document.querySelector('.modal.show');
        if (openModal) {
          closeModal(openModal);
        }
      }
    });

    // Fix close buttons
    document.querySelectorAll('[data-bs-dismiss="modal"], .modal-close-btn').forEach(btn => {
      btn.addEventListener('click', function() {
        const modal = this.closest('.modal');
        if (modal) {
          closeModal(modal);
        }
      });
    });
  }

  // Initialize on page load
  initializeModals();

  // Re-initialize on dynamic content load (for AJAX)
  if (typeof Turbo !== 'undefined') {
    document.addEventListener('turbo:load', initializeModals);
  }

  console.log('✅ Modal fixes initialized');
});

// Alternative custom modal system (if Bootstrap is problematic)
window.showCustomModal = function(content, title = '') {
  // Remove existing modal if any
  const existingModal = document.querySelector('.custom-modal');
  if (existingModal) {
    existingModal.remove();
  }

  // Create modal
  const modal = document.createElement('div');
  modal.className = 'custom-modal';
  modal.innerHTML = `
    <div class="custom-modal-content">
      <button class="modal-close-btn" onclick="closeCustomModal()">&times;</button>
      ${title ? `<h3 style="margin-bottom: 20px;">${title}</h3>` : ''}
      ${content}
    </div>
  `;

  document.body.appendChild(modal);

  // Show modal
  setTimeout(() => modal.classList.add('show'), 10);

  return modal;
};

window.closeCustomModal = function() {
  const modal = document.querySelector('.custom-modal');
  if (modal) {
    modal.classList.remove('show');
    setTimeout(() => modal.remove(), 300);
  }
};
