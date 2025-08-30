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

// Add animation on scroll for certification cards
const certificationCards = document.querySelectorAll('.certification-card');
const certObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = 1;
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, { threshold: 0.2 });

certificationCards.forEach(card => {
    card.style.opacity = 0;
    card.style.transform = 'translateY(20px)';
    card.style.transition = 'opacity 0.6s, transform 0.6s';
    certObserver.observe(card);
});

// VISITOR COUNTER FUNCTIONALITY
class VisitorCounter {
    constructor() {
        this.functionUrl = null;
        this.countElement = document.getElementById('visitor-count');
        this.init();
    }

    async init() {
        console.log('Initializing visitor counter...');
        
        // TODO: Replace with your actual Azure Function URL after Terraform deployment
        // Format: https://[YOUR_FUNCTION_APP_NAME].azurewebsites.net/api/visitor
        this.functionUrl = 'PLACEHOLDER_AZURE_FUNCTION_URL/api/visitor';
        
        // Check if the URL has been updated from placeholder
        if (this.functionUrl.includes('PLACEHOLDER_AZURE_FUNCTION_URL')) {
            console.error('⚠️  Azure Function URL not configured! Please update PLACEHOLDER_AZURE_FUNCTION_URL with your actual function app URL.');
            this.countElement.textContent = 'URL not configured';
            this.countElement.className = 'visitor-count error';
            return;
        }
        
        // Check if element exists
        if (!this.countElement) {
            console.error('Visitor count element not found! Make sure element with id="visitor-count" exists.');
            return;
        }
        
        // Initialize the counter
        await this.updateVisitorCount();
    }

    async updateVisitorCount() {
        if (!this.countElement) {
            console.log('Visitor count element not found');
            return;
        }

        try {
            console.log('Attempting to connect to:', this.functionUrl);
            
            // Set loading state
            this.countElement.textContent = 'Loading...';
            this.countElement.className = 'visitor-count loading';

            // Test connection first with a timeout
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout

            // First, try to get current count
            let response = await fetch(this.functionUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                signal: controller.signal,
                mode: 'cors'
            });

            clearTimeout(timeoutId);

            console.log('GET Response status:', response.status);
            console.log('GET Response headers:', response.headers);

            if (!response.ok) {
                const errorText = await response.text();
                console.error('GET Request failed:', response.status, errorText);
                throw new Error(`GET request failed with status: ${response.status}`);
            }

            let data = await response.json();
            console.log('Current visitor count:', data.count);

            // Now increment the count by sending a POST request
            const controller2 = new AbortController();
            const timeoutId2 = setTimeout(() => controller2.abort(), 10000);

            response = await fetch(this.functionUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                signal: controller2.signal,
                mode: 'cors'
            });

            clearTimeout(timeoutId2);

            console.log('POST Response status:', response.status);

            if (!response.ok) {
                const errorText = await response.text();
                console.error('POST Request failed:', response.status, errorText);
                throw new Error(`POST request failed with status: ${response.status}`);
            }

            data = await response.json();
            console.log('Updated visitor count:', data.count);

            // Update the display with animation
            this.animateCounterUpdate(data.count);

        } catch (error) {
            console.error('Error updating visitor count:', error);
            
            // More specific error handling
            if (error.name === 'AbortError') {
                this.countElement.textContent = 'Request timeout';
            } else if (error.message.includes('Failed to fetch')) {
                this.countElement.textContent = 'Connection failed';
            } else {
                this.countElement.textContent = 'Unable to load';
            }
            
            this.countElement.className = 'visitor-count error';
            
            // Fallback: try to show a static number
            setTimeout(() => {
                this.countElement.textContent = '---';
                this.countElement.className = 'visitor-count fallback';
            }, 3000);
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
    console.log('DOM loaded, initializing visitor counter...');
    
    // Initialize visitor counter
    const visitorCounter = new VisitorCounter();
    
    // Make it globally accessible for debugging
    window.visitorCounter = visitorCounter;
    
    // Optional: Add some delay to let the page fully load
    setTimeout(() => {
        console.log('Visitor counter initialization complete');
    }, 1000);
});

// Health check function for debugging
async function checkAPIHealth() {
    // TODO: Replace with your actual Azure Function URL after Terraform deployment
    const healthUrl = 'PLACEHOLDER_AZURE_FUNCTION_URL/api/health';
    
    if (healthUrl.includes('PLACEHOLDER_AZURE_FUNCTION_URL')) {
        console.error('⚠️  Cannot run health check: Azure Function URL not configured!');
        return false;
    }
    
    try {
        console.log('Checking API health at:', healthUrl);
        const response = await fetch(healthUrl);
        const data = await response.json();
        console.log('API Health Check SUCCESS:', data);
        return true;
    } catch (error) {
        console.error('API Health Check FAILED:', error);
        return false;
    }
}

// Debug function to test the visitor endpoint
async function testVisitorEndpoint() {
    // TODO: Replace with your actual Azure Function URL after Terraform deployment
    const visitorUrl = 'PLACEHOLDER_AZURE_FUNCTION_URL/api/visitor';
    
    if (visitorUrl.includes('PLACEHOLDER_AZURE_FUNCTION_URL')) {
        console.error('⚠️  Cannot test endpoint: Azure Function URL not configured!');
        return;
    }
    
    console.log('=== TESTING VISITOR ENDPOINT ===');
    
    try {
        // Test GET request
        console.log('Testing GET request...');
        let response = await fetch(visitorUrl, { method: 'GET' });
        console.log('GET Response status:', response.status);
        let data = await response.json();
        console.log('GET Response data:', data);
        
        // Test POST request
        console.log('Testing POST request...');
        response = await fetch(visitorUrl, { method: 'POST' });
        console.log('POST Response status:', response.status);
        data = await response.json();
        console.log('POST Response data:', data);
        
    } catch (error) {
        console.error('Test failed:', error);
    }
}

// Run health check automatically for debugging (only if URL is configured)
setTimeout(() => {
    if (!window.location.href.includes('PLACEHOLDER_AZURE_FUNCTION_URL')) {
        checkAPIHealth();
    }
}, 2000);

// Expose test functions globally for manual testing
window.testVisitorEndpoint = testVisitorEndpoint;
window.checkAPIHealth = checkAPIHealth;