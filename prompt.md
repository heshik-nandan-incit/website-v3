You are my website developer.

Your task is to build a fully functional website using only the existing HTML, code, assets, and content inside the reference folder.

⸻

⚠️ Important context (READ FIRST)

The reference folder contains pages that were scraped from the internet using a sitemap.
	•	The current folder/file structure DOES NOT reflect the actual site hierarchy
	•	It is flat and unstructured
	•	Some pages may appear duplicated or misplaced

✅ Critical instruction

You must reconstruct the correct site hierarchy based on the navigation (menus, headers, footers, internal links) — NOT based on the current folder structure.
	•	Use:
	•	Navigation menus (header/footer)
	•	Internal linking patterns
	•	URL structures inside the files
	•	Do NOT assume the current folder structure is correct

⸻

Core instruction

Do not invent new content, layouts, or design directions unless explicitly instructed.
Your job is to transform the provided reference materials into a clean, production-ready website.

⸻

Mandatory rules

1. Use only provided content
	•	Use only files, HTML, text, images, and assets in the reference folder
	•	No dummy content, placeholders, or invented sections
	•	If something is missing but required, keep it minimal and clearly flag it

⸻

2. Reconstruct proper hierarchy (CRITICAL)
	•	Build the site structure based on actual navigation flow, not file structure
	•	Group pages logically (e.g. /about, /services, /products, etc.)
	•	Ensure URLs reflect real user navigation
	•	Fix duplicated or inconsistent page paths

⸻

3. Reuse components
	•	Identify repeating UI patterns and convert them into reusable components:
	•	Header / Footer
	•	Navigation
	•	Hero sections
	•	Cards / Lists
	•	Buttons / Forms
	•	Content blocks
	•	Avoid duplication — prioritize modular structure

⸻

4. Strict design fidelity
	•	Follow the design exactly as provided
	•	Do NOT:
	•	Change spacing, colors, fonts
	•	Modify layout structure
	•	Improve UI “creatively”
	•	If unclear, choose the closest match to the original

⸻

5. Responsive implementation
	•	Fully optimize for:
	•	Mobile
	•	Desktop
	•	Maintain design consistency across breakpoints
	•	Ensure usability, readability, and layout stability

⸻

6. API and data handling
	•	Where APIs are present:
	•	Connect properly
	•	Retrieve and render data correctly
	•	Include:
	•	Loading states
	•	Empty states
	•	Error handling
	•	Do NOT mock APIs unless explicitly told

⸻

7. Image optimization
	•	Optimize all images for performance
	•	Use correct formats, sizes, and lazy loading
	•	Ensure no layout shifts or broken rendering

⸻

8. S3 hosting compatibility (IMPORTANT)

This site will be hosted on Amazon S3 (static hosting)
	•	Ensure:
	•	All links are static-safe (no server routing assumptions)
	•	Correct use of relative/absolute paths
	•	No dependency on backend routing unless explicitly configured
	•	Avoid SPA routing issues unless properly handled

⸻

9. Link validation
	•	Test ALL:
	•	Navigation links
	•	Buttons
	•	Cross-page references
	•	Ensure:
	•	No broken links
	•	Correct routing between pages

⸻

10. Functional completeness
	•	Deliver a working, production-ready website
	•	Clean, maintainable structure
	•	All pages accessible and connected

⸻

Working approach
	1.	Scan and understand the entire reference folder
	2.	Identify navigation structure and rebuild hierarchy
	3.	Define reusable components
	4.	Reconstruct pages using correct hierarchy
	5.	Ensure design fidelity
	6.	Connect APIs where required
	7.	Optimize assets (especially images)
	8.	Make fully responsive
	9.	Validate all links and navigation
	10.	Ensure S3 compatibility

⸻

Output expectations

Provide:

1. Complete codebase
	•	Clean folder structure based on reconstructed hierarchy
	•	Component-based architecture

2. Notes on issues found
	•	Missing files
	•	Broken references
	•	Duplicate pages
	•	Ambiguous hierarchy decisions (if any)

3. Validation summary
	•	Pages completed
	•	Components created
	•	Hierarchy reconstructed (explain briefly)
	•	APIs connected
	•	Image optimization done
	•	Responsive checks done
	•	Broken links fixed
	•	S3 compatibility confirmed

⸻

Final constraint
	•	Do not redesign
	•	Do not simplify unnecessarily
	•	Do not follow the existing folder structure blindly
	•	Hierarchy must reflect real navigation, not scraped structure

Your goal is to take a messy scraped dataset and turn it into a clean, structured, production-grade website.
:::
