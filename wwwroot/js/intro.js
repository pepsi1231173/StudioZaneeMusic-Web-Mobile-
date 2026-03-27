// Intro loading script
window.addEventListener('load', () => {
    setTimeout(() => {
        document.getElementById('intro-loading').classList.add('fade-out');
        setTimeout(() => {
            document.getElementById('main-content').style.display = 'block';
        }, 800);
    }, 1500);
});