(function () {
  function createBackdrop(closeHandler) {
    var backdrop = document.querySelector(".incit-card-backdrop");
    if (backdrop) {
      return backdrop;
    }

    backdrop = document.createElement("div");
    backdrop.className = "incit-card-backdrop";
    backdrop.addEventListener("click", closeHandler);
    document.body.appendChild(backdrop);
    document.body.style.overflow = "hidden";
    return backdrop;
  }

  function deleteBackdrop() {
    var backdrop = document.querySelector(".incit-card-backdrop");
    if (backdrop) {
      backdrop.remove();
    }
    document.body.style.overflow = "auto";
  }

  function initWidget(widget) {
    if (!widget || widget.dataset.incitCardModalInitialized === "true") {
      return;
    }
    widget.dataset.incitCardModalInitialized = "true";

    var swiperEl = widget.querySelector(".swiper[id]");
    var sliderPrev = widget.querySelector(".incit-card-navigation-wrapper .incit-card-prev");
    var sliderNext = widget.querySelector(".incit-card-navigation-wrapper .incit-card-next");

    if (swiperEl && window.Swiper) {
      new window.Swiper(swiperEl, {
        navigation: {
          nextEl: sliderNext,
          prevEl: sliderPrev,
        },
        slidesPerView: 1,
        spaceBetween: 20,
        breakpoints: {
          1024: {
            slidesPerView: 2,
          },
        },
      });
    }

    function resolveTargetModal(targetId) {
      if (!targetId) return null;
      return widget.querySelector("#" + targetId + " .incit-card-modal");
    }

    function closeModal() {
      var current = widget.querySelector(".incit-card-modal.incit-modal-active");
      deleteBackdrop();
      if (current) {
        current.classList.remove("incit-modal-active");
        current.classList.remove("incit-modal-fade-left");
        current.classList.remove("incit-modal-fade-right");
      }
    }

    function openModalByTarget(targetId) {
      createBackdrop(closeModal);
      var current = widget.querySelector(".incit-card-modal.incit-modal-active");
      if (current) {
        current.classList.remove("incit-modal-active");
      }
      var target = resolveTargetModal(targetId);
      if (target) {
        target.classList.add("incit-modal-active");
      }
    }

    function transitionModal(button, exitClass, enterClass) {
      createBackdrop(closeModal);
      var current = widget.querySelector(".incit-card-modal.incit-modal-active");
      var targetId = button && button.getAttribute("incit-modal-target");
      var target = resolveTargetModal(targetId);
      if (!current || !target) {
        if (target) {
          target.classList.add("incit-modal-active");
        }
        return;
      }

      current.classList.add(exitClass);
      current.addEventListener(
        "transitionend",
        function () {
          current.classList.remove(exitClass);
          current.classList.remove("incit-modal-active");
          target.classList.add(enterClass);
          target.classList.add("incit-modal-active");
          target.addEventListener(
            "transitionend",
            function () {
              target.classList.remove(enterClass);
            },
            { once: true }
          );
        },
        { once: true }
      );
    }

    widget.querySelectorAll(".incit-card:not(.incit-card-link)").forEach(function (card) {
      card.addEventListener("click", function () {
        openModalByTarget(card.getAttribute("incit-modal-target"));
      });
    });

    widget.querySelectorAll(".incit-card-close-button").forEach(function (button) {
      button.addEventListener("click", closeModal);
    });

    widget
      .querySelectorAll(".incit-card-navigation-buttons[nav-button-type='prev']")
      .forEach(function (button) {
        button.addEventListener("click", function () {
          transitionModal(button, "incit-modal-fade-right", "incit-modal-fade-left");
        });
      });

    widget
      .querySelectorAll(".incit-card-navigation-buttons[nav-button-type='next']")
      .forEach(function (button) {
        button.addEventListener("click", function () {
          transitionModal(button, "incit-modal-fade-left", "incit-modal-fade-right");
        });
      });
  }

  window.addEventListener("load", function () {
    document.querySelectorAll(".elementor-widget-card-siri-slider").forEach(initWidget);
  });
})();
