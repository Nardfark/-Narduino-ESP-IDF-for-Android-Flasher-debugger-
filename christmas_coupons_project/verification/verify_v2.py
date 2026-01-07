from playwright.sync_api import sync_playwright

def verify_frontend():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # 1. Redeem Page
        page.goto("http://localhost:6969/redeem.html")
        page.wait_for_selector(".card")
        page.screenshot(path="verification/redeem_page.png")
        print("Captured redeem_page.png")

        # 2. Print Page
        page.goto("http://localhost:6969/print.html")
        page.wait_for_selector(".coupon-qr img")
        page.screenshot(path="verification/print_page.png")
        print("Captured print_page.png")

        browser.close()

if __name__ == "__main__":
    verify_frontend()
