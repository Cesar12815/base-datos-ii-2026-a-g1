document.addEventListener('DOMContentLoaded', () => {
    const navLinks = document.querySelectorAll('.main-nav ul li a');
    const sections = document.querySelectorAll('section');

    function changeActiveNav() {
        let index = sections.length;
        while(--index && window.scrollY + 150 < sections[index].offsetTop) {}

        navLinks.forEach((link) => link.classList.remove('active'));
        if (index >= 0 && index < navLinks.length) {
            if (window.scrollY < 200) {
                navLinks[0].classList.add('active');
            } else {
                if(navLinks[index]) navLinks[index].classList.add('active');
            }
        }
    }

    window.addEventListener('scroll', changeActiveNav);

    const scrollTopBtn = document.getElementById("scrollTopBtn");

    window.onscroll = function() {scrollFunction()};

    function scrollFunction() {
      if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
        scrollTopBtn.style.display = "block";
      } else {
        scrollTopBtn.style.display = "none";
      }
    }

    scrollTopBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    const tableRows = document.querySelectorAll('.styled-table tbody tr');
    tableRows.forEach(row => {
        row.addEventListener('mouseenter', () => {
            row.style.transform = "scale(1.01)";
            row.style.transition = "transform 0.2s ease";
            row.style.boxShadow = "0 4px 8px rgba(0,0,0,0.1)";
        });
        row.addEventListener('mouseleave', () => {
            row.style.transform = "scale(1)";
            row.style.boxShadow = "none";
        });
    });
});

