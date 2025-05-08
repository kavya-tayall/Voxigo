// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize AOS (Animate on Scroll)
    if (typeof AOS !== 'undefined') {
        AOS.init({
            duration: 800,
            easing: 'ease-in-out',
            once: true
        });
    }

    // Mobile Navigation Toggle
    const header = document.querySelector('header');
    const navToggle = document.querySelector('.nav-toggle');
    
    if (navToggle) {
        navToggle.addEventListener('click', function() {
            header.classList.toggle('nav-active');
            this.classList.toggle('active');
        });
    }

    // FAQ Toggle
    const faqItems = document.querySelectorAll('.faq');
    
    if (faqItems.length > 0) {
        faqItems.forEach(faq => {
            faq.addEventListener('click', function() {
                this.classList.toggle('active');
            });
        });
    }
    
    // FAQ Category Tabs
    const categoryTabs = document.querySelectorAll('.category-tab');
    const faqContainers = document.querySelectorAll('.faq-container');
    
    if (categoryTabs.length > 0 && faqContainers.length > 0) {
        categoryTabs.forEach(tab => {
            tab.addEventListener('click', function() {
                // Update active tab
                categoryTabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
                
                // Show corresponding FAQ container
                const category = this.getAttribute('data-category');
                faqContainers.forEach(container => {
                    container.classList.add('hidden');
                });
                document.getElementById(category).classList.remove('hidden');
            });
        });
    }

    // Feature Category Tabs on features.html
    const featureCategoryTabs = document.querySelectorAll('.faq-categories .category-tab');
    const featureContainers = document.querySelectorAll('.feature-container');
    
    if (featureCategoryTabs.length > 0 && featureContainers.length > 0) {
        featureCategoryTabs.forEach(tab => {
            tab.addEventListener('click', function() {
                // Update active tab
                featureCategoryTabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
                
                // Show corresponding feature container
                const category = this.getAttribute('data-category');
                featureContainers.forEach(container => {
                    container.classList.add('hidden');
                });
                document.getElementById(category).classList.remove('hidden');
            });
        });
    }

    // Smooth Scrolling for Anchor Links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 100,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Testimonial Slider
    const testimonialSlider = document.querySelector('.testimonial-slider');
    if (testimonialSlider) {
        let currentSlide = 0;
        const slides = testimonialSlider.querySelectorAll('.testimonial-slide');
        const totalSlides = slides.length;
        const nextBtn = document.querySelector('.testimonial-next');
        const prevBtn = document.querySelector('.testimonial-prev');
        let autoScrollInterval;
        
        function showSlide(index) {
            testimonialSlider.style.transform = `translateX(-${index * 100}%)`;
        }
        
        function resetAutoScroll() {
            // Clear existing interval
            if (autoScrollInterval) {
                clearInterval(autoScrollInterval);
            }
            
            // Don't restart auto-scroll - removed auto-scrolling entirely
        }
        
        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                currentSlide = (currentSlide + 1) % totalSlides;
                showSlide(currentSlide);
                resetAutoScroll();
            });
        }
        
        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                currentSlide = (currentSlide - 1 + totalSlides) % totalSlides;
                showSlide(currentSlide);
                resetAutoScroll();
            });
        }
        
        // Initialize the slider
        showSlide(currentSlide);
        
        // Remove auto-scrolling entirely
    }
    
    // Feature Animation on Hover
    const features = document.querySelectorAll('.feature');
    if (features.length > 0) {
        features.forEach(feature => {
            feature.addEventListener('mouseenter', function() {
                const icon = this.querySelector('.feature-icon');
                if (icon) icon.classList.add('pulse');
            });
            
            feature.addEventListener('mouseleave', function() {
                const icon = this.querySelector('.feature-icon');
                if (icon) icon.classList.remove('pulse');
            });
        });
    }
    
    // Form Validation
    const contactForm = document.querySelector('#contact-form');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            let isValid = true;
            const nameInput = this.querySelector('#name');
            const emailInput = this.querySelector('#email');
            const messageInput = this.querySelector('#message');
            
            // Simple validation
            if (nameInput && nameInput.value.trim() === '') {
                isValid = false;
                showError(nameInput, 'Please enter your name');
            } else if (nameInput) {
                clearError(nameInput);
            }
            
            if (emailInput) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(emailInput.value)) {
                    isValid = false;
                    showError(emailInput, 'Please enter a valid email');
                } else {
                    clearError(emailInput);
                }
            }
            
            if (messageInput && messageInput.value.trim() === '') {
                isValid = false;
                showError(messageInput, 'Please enter your message');
            } else if (messageInput) {
                clearError(messageInput);
            }
            
            if (isValid) {
                // Show success message
                const successMessage = document.createElement('div');
                successMessage.classList.add('success-message');
                successMessage.innerText = 'Thank you! Your message has been sent successfully.';
                
                this.innerHTML = '';
                this.appendChild(successMessage);
                
                // In a real application, you would send the form data to a server here
            }
        });
        
        function showError(input, message) {
            const formControl = input.parentElement;
            const errorElement = formControl.querySelector('.error-message') || document.createElement('div');
            
            errorElement.classList.add('error-message');
            errorElement.innerText = message;
            
            if (!formControl.querySelector('.error-message')) {
                formControl.appendChild(errorElement);
            }
            
            input.classList.add('error');
        }
        
        function clearError(input) {
            const formControl = input.parentElement;
            const errorElement = formControl.querySelector('.error-message');
            
            if (errorElement) {
                formControl.removeChild(errorElement);
            }
            
            input.classList.remove('error');
        }
    }
    
    // Sticky Header on Scroll
    const stickyHeader = document.querySelector('header');
    if (stickyHeader) {
        window.addEventListener('scroll', function() {
            if (window.pageYOffset > 50) {
                stickyHeader.classList.add('sticky');
            } else {
                stickyHeader.classList.remove('sticky');
            }
        });
    }
    
    // Back to Top Button
    const backToTopBtn = document.createElement('button');
    backToTopBtn.classList.add('back-to-top');
    backToTopBtn.innerHTML = '<i class="fas fa-arrow-up"></i>';
    document.body.appendChild(backToTopBtn);
    
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            backToTopBtn.classList.add('visible');
        } else {
            backToTopBtn.classList.remove('visible');
        }
    });
    
    backToTopBtn.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
});

// Add some CSS to the page for the back to top button
const style = document.createElement('style');
style.innerHTML = `
    .back-to-top {
        position: fixed;
        bottom: 30px;
        right: 30px;
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background-color: var(--primary);
        color: white;
        font-size: 20px;
        border: none;
        cursor: pointer;
        display: flex;
        justify-content: center;
        align-items: center;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s ease;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
        z-index: 1000;
    }
    
    .back-to-top.visible {
        opacity: 1;
        visibility: visible;
    }
    
    .back-to-top:hover {
        transform: translateY(-5px);
        box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
    }
    
    /* Pulse animation for features */
    @keyframes pulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.1); }
        100% { transform: scale(1); }
    }
    
    .feature-icon.pulse {
        animation: pulse 0.8s ease-in-out;
    }
    
    /* Error and success styles for forms */
    .error {
        border-color: #ff4d4d !important;
    }
    
    .error-message {
        color: #ff4d4d;
        font-size: 0.8rem;
        margin-top: 5px;
    }
    
    .success-message {
        text-align: center;
        color: #28a745;
        font-size: 1.2rem;
        padding: 20px;
        background-color: rgba(40, 167, 69, 0.1);
        border-radius: 10px;
        margin: 20px 0;
    }
    
    /* Sticky header styles */
    header.sticky {
        padding: 0.5rem 2rem;
        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
    }
    
    /* Navigation for mobile */
    .nav-toggle {
        display: none;
    }
    
    @media (max-width: 768px) {
        .nav-toggle {
            display: block;
            width: 30px;
            height: 20px;
            position: relative;
            cursor: pointer;
        }
        
        .nav-toggle span {
            display: block;
            position: absolute;
            height: 3px;
            width: 100%;
            background: var(--primary);
            border-radius: 3px;
            transition: all 0.3s ease;
        }
        
        .nav-toggle span:nth-child(1) {
            top: 0;
        }
        
        .nav-toggle span:nth-child(2) {
            top: 8px;
        }
        
        .nav-toggle span:nth-child(3) {
            top: 16px;
        }
        
        .nav-toggle.active span:nth-child(1) {
            top: 8px;
            transform: rotate(45deg);
        }
        
        .nav-toggle.active span:nth-child(2) {
            opacity: 0;
        }
        
        .nav-toggle.active span:nth-child(3) {
            top: 8px;
            transform: rotate(-45deg);
        }
        
        header nav {
            display: none;
            width: 100%;
            flex-direction: column;
            align-items: center;
            padding: 20px 0;
        }
        
        header.nav-active nav {
            display: flex;
        }
    }
`;
document.head.appendChild(style); 