// Visitor Counter Functionality
class VisitorCounter {
    constructor() {
        this.apiUrl = this.getApiUrl();
        this.counterElement = document.getElementById('visitor-count');
        this.init();
    }

    getApiUrl() {
        // In production, this will be your Function App URL
        // For local development, you might use localhost
        const isProduction = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';
        
        if (isProduction) {
            // Replace with your actual Function App URL
            return 'https://azure-resume-func-default.azurewebsites.net/api/visitor';
        } else {
            // Local development URL
            return 'http://localhost:7071/api/visitor';
        }
    }

    async init() {
        try {
            // First, get the current count
            await this.getCurrentCount();
            
            // Then increment the count (new visitor)
            await this.incrementCount();
        } catch (error) {
            console.error('Error initializing visitor counter:', error);
            this.showError();
        }
    }

    async getCurrentCount() {
        try {
            const response = await fetch(this.apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            this.updateDisplay(data.count);
        } catch (error) {
            console.error('Error getting current count:', error);
            throw error;
        }
    }

    async incrementCount() {
        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            this.updateDisplay(data.count);
            this.animateCounter();
        } catch (error) {
            console.error('Error incrementing count:', error);
            // Don't throw here - we already have the count from GET request
        }
    }

    updateDisplay(count) {
        if (this.counterElement) {
            // Add commas to large numbers
            const formattedCount = count.toLocaleString();
            this.counterElement.textContent = formattedCount;
        }
    }

    animateCounter() {
        if (this.counterElement) {
            // Add a subtle animation when the counter updates
            this.counterElement.style.transform = 'scale(1.1)';
            this.counterElement.style.transition = 'transform 0.3s ease';
            
            setTimeout(() => {
                this.counterElement.style.transform = 'scale(1)';
            }, 300);
        }
    }

    showError() {
        if (this.counterElement) {
            this.counterElement.textContent = 'Error';
            this.counterElement.style.color = '#ef4444';
        }
    }
}

// Smooth scrolling for internal links (if any)
function initSmoothScrolling() {
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Add loading animations
function initAnimations() {
    // Fade in sections as they come into view
    const sections = document.querySelectorAll('.section');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });

    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(20px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(section);
    });
}

// Add skill tag hover effects
function initSkillTags() {
    const skillTags = document.querySelectorAll('.skill-tag');
    
    skillTags.forEach(tag => {
        tag.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px) scale(1.05)';
        });
        
        tag.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
}

// Print functionality
function initPrintStyles() {
    // Add print button if needed
    const printButton = document.createElement('button');
    printButton.innerHTML = '<i class="fas fa-print"></i> Print Resume';
    printButton.className = 'print-button';
    printButton.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: linear-gradient(135deg, #4f46e5, #7c3aed);
        color: white;
        border: none;
        padding: 12px 20px;
        border-radius: 25px;
        cursor: pointer;
        font-weight: 500;
        box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
        transition: transform 0.3s ease;
        z-index: 1000;
    `;
    
    printButton.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-2px)';
    });
    
    printButton.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
    });
    
    printButton.addEventListener('click', function() {
        window.print();
    });
    
    document.body.appendChild(printButton);
}

// Dark mode toggle (optional enhancement)
function initDarkMode() {
    // You can add dark mode functionality here if desired
    // This would toggle between light and dark themes
}

// Initialize everything when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize visitor counter
    new VisitorCounter();
    
    // Initialize other features
    initSmoothScrolling();
    initAnimations();
    initSkillTags();
    initPrintStyles();
    
    // Add a subtle loading indicator removal
    setTimeout(() => {
        document.body.style.opacity = '1';
        document.body.style.transition = 'opacity 0.5s ease';
    }, 100);
});

// Handle any errors globally
window.addEventListener('error', function(e) {
    console.error('Global error:', e.error);
});

// Performance monitoring (optional)
window.addEventListener('load', function() {
    if ('performance' in window) {
        const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
        console.log(`Page loaded in ${loadTime}ms`);
    }
});