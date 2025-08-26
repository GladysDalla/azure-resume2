// Smooth scrolling for navigation links
document.querySelectorAll('nav a').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const sectionId = this.getAttribute('href');
        document.querySelector(sectionId).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

// Add animation on scroll for project cards
const projectCards = document.querySelectorAll('.project-card');
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = 1;
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, { threshold: 0.2 });

projectCards.forEach(card => {
    card.style.opacity = 0;
    card.style.transform = 'translateY(20px)';
    card.style.transition = 'opacity 0.5s, transform 0.5s';
    observer.observe(card);
});

// Tabbed filtering for projects
const tabButtons = document.querySelectorAll('.tab-button');
const projectCardsAll = document.querySelectorAll('.project-card');

tabButtons.forEach(button => {
    button.addEventListener('click', () => {
        // Remove active class from all buttons
        tabButtons.forEach(btn => btn.classList.remove('active'));
        // Add active class to clicked button
        button.classList.add('active');

        const category = button.getAttribute('data-category');

        // Show/hide project cards based on category
        projectCardsAll.forEach(card => {
            if (category === 'all' || card.classList.contains(category)) {
                card.classList.add('active');
            } else {
                card.classList.remove('active');
            }
        });
    });
});

// VISITOR COUNTER FUNCTIONALITY
class VisitorCounter {
    constructor() {
        this.functionUrl = null;
        this.countElement = document.getElementById('visitor-count');
        this.init();
    }

    async init() {
        // Get the function URL - you'll need to replace this with your actual function app URL
        this.functionUrl = 'https://YOUR_FUNCTION_APP_NAME.azurewebsites.net/api/visitor';
        
        // Initialize the counter
        await this.updateVisitorCount();
    }

    async updateVisitorCount() {
        if (!this.countElement) {
            console.log('Visitor count element not found');
            return;
        }

        try {
            // Set loading state
            this.countElement.textContent = 'Loading...';
            this.countElement.className = 'visitor-count loading';

            // First, try to get current count
            let response = await fetch(this.functionUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            let data = await response.json();
            console.log('Current visitor count:', data.count);

            // Now increment the count by sending a POST request
            response = await fetch(this.functionUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            data = await response.json();
            console.log('Updated visitor count:', data.count);

            // Update the display with animation
            this.animateCounterUpdate(data.count);

        } catch (error) {
            console.error('Error updating visitor count:', error);
            this.countElement.textContent = 'Unable to load';
            this.countElement.className = 'visitor-count error';
        }
    }

    animateCounterUpdate(finalCount) {
        const startCount = 0;
        const duration = 1500; // 1.5 seconds
        const startTime = Date.now();

        const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Use easing function for smooth animation
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const currentCount = Math.floor(startCount + (finalCount - startCount) * easeOutQuart);
            
            this.countElement.textContent = currentCount.toLocaleString();
            this.countElement.className = 'visitor-count';
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            } else {
                this.countElement.textContent = finalCount.toLocaleString();
            }
        };

        animate();
    }

    // Method to get current count without incrementing
    async getCurrentCount() {
        try {
            const response = await fetch(this.functionUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            return data.count;
        } catch (error) {
            console.error('Error getting current count:', error);
            return 0;
        }
    }
}

// Initialize visitor counter when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize visitor counter
    const visitorCounter = new VisitorCounter();
    
    // Optional: Add some delay to let the page fully load
    setTimeout(() => {
        console.log('Visitor counter initialized');
    }, 1000);
});

// Optional: Health check for the API
async function checkAPIHealth() {
    try {
        const response = await fetch('https://YOUR_FUNCTION_APP_NAME.azurewebsites.net/api/health');
        const data = await response.json();
        console.log('API Health Check:', data);
    } catch (error) {
        console.error('API Health Check failed:', error);
    }
}

// Run health check (optional)
// checkAPIHealth();