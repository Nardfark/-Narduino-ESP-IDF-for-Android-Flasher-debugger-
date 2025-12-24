from playwright.sync_api import sync_playwright

def verify_double_sided():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        page.goto("http://localhost:6969/print.html")
        page.wait_for_selector(".coupon")

        # Verify Front Page exists
        if page.locator(".page.front").count() == 0:
            print("FAILED: Front page not found")
        else:
            print("SUCCESS: Front page found")

        # Verify Back Page exists
        if page.locator(".page.back").count() == 0:
            print("FAILED: Back page not found")
        else:
            print("SUCCESS: Back page found")

        # Verify Back Content (Serial)
        if page.locator(".back-serial").count() == 0:
             print("FAILED: Back serial number not found")
        else:
             print("SUCCESS: Back serial number found")

        page.screenshot(path="verification/print_double_sided.png")
        print("Captured screenshot")

        browser.close()

if __name__ == "__main__":
    verify_double_sided()
