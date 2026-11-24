(function (global) {
    "use strict";

    const DEFAULT_SIZES = [5, 10, 20, 50];

    function buildPageNumbers(current, total) {
        const items = [];
        const start = Math.max(1, current - 2);
        const end = Math.min(total, current + 2);

        if (start > 1) {
            items.push(1);
            if (start > 2) {
                items.push("...");
            }
        }
        for (let p = start; p <= end; p++) {
            items.push(p);
        }
        if (end < total) {
            if (end < total - 1) {
                items.push("...");
            }
            items.push(total);
        }
        return items;
    }

    function renderControls(container, opts) {
        if (!container) return;

        const totalItems = Math.max(0, opts.totalItems || 0);
        const pageSize = opts.pageSize || 10;
        const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
        const page = Math.min(Math.max(1, opts.page || 1), totalPages);
        const label = opts.label || "registros";
        const sizes = opts.sizes || DEFAULT_SIZES;

        const startIdx = totalItems === 0 ? 0 : (page - 1) * pageSize + 1;
        const endIdx = totalItems === 0 ? 0 : Math.min(page * pageSize, totalItems);

        container.classList.add("lumyn-pagination-bar");
        container.innerHTML = "";

        const left = document.createElement("div");
        left.className = "lumyn-pagination-info";

        const countSpan = document.createElement("span");
        if (totalItems === 0) {
            countSpan.textContent = "Mostrando 0 " + label;
        } else {
            countSpan.textContent =
                "Mostrando " + startIdx + "–" + endIdx + " de " + totalItems + " " + label +
                " (Página " + page + " de " + totalPages + ")";
        }
        left.appendChild(countSpan);

        if (totalItems > 0 && typeof opts.onPageSizeChange === "function") {
            const sizeWrap = document.createElement("label");
            sizeWrap.className = "lumyn-page-size-wrap";
            sizeWrap.appendChild(document.createTextNode("Mostrar "));

            const select = document.createElement("select");
            select.className = "form-control lumyn-page-size";
            select.setAttribute("aria-label", "Registros por página");
            sizes.forEach(function (sz) {
                const option = document.createElement("option");
                option.value = String(sz);
                option.textContent = String(sz);
                if (sz === pageSize) {
                    option.selected = true;
                }
                select.appendChild(option);
            });
            select.addEventListener("change", function () {
                opts.onPageSizeChange(parseInt(this.value, 10) || 10);
            });
            sizeWrap.appendChild(select);
            left.appendChild(sizeWrap);
        }

        container.appendChild(left);

        if (totalPages > 1 && typeof opts.onPageChange === "function") {
            const nav = document.createElement("nav");
            nav.className = "pagination";
            nav.setAttribute("aria-label", "Paginación de " + label);

            const prevBtn = document.createElement("button");
            prevBtn.type = "button";
            prevBtn.className = "page-link" + (page <= 1 ? " disabled" : "");
            prevBtn.disabled = page <= 1;
            prevBtn.textContent = "« Anterior";
            prevBtn.addEventListener("click", function () {
                if (page > 1) opts.onPageChange(page - 1);
            });
            nav.appendChild(prevBtn);

            buildPageNumbers(page, totalPages).forEach(function (item) {
                if (item === "...") {
                    const ellipsis = document.createElement("span");
                    ellipsis.className = "page-ellipsis";
                    ellipsis.textContent = "…";
                    nav.appendChild(ellipsis);
                } else {
                    const btn = document.createElement("button");
                    btn.type = "button";
                    btn.className = "page-link" + (item === page ? " active" : "");
                    btn.textContent = String(item);
                    if (item === page) {
                        btn.setAttribute("aria-current", "page");
                    }
                    btn.addEventListener("click", function () {
                        if (item !== page) opts.onPageChange(item);
                    });
                    nav.appendChild(btn);
                }
            });

            const nextBtn = document.createElement("button");
            nextBtn.type = "button";
            nextBtn.className = "page-link" + (page >= totalPages ? " disabled" : "");
            nextBtn.disabled = page >= totalPages;
            nextBtn.textContent = "Siguiente »";
            nextBtn.addEventListener("click", function () {
                if (page < totalPages) opts.onPageChange(page + 1);
            });
            nav.appendChild(nextBtn);

            container.appendChild(nav);
        }
    }

    function attachTable(options) {
        const tbody = typeof options.tbody === "string"
            ? document.querySelector(options.tbody)
            : options.tbody;
        if (!tbody) return null;

        const rowSelector = options.rowSelector || "tr";
        const allRows = Array.from(tbody.querySelectorAll(rowSelector)).filter(function (row) {
            // Ignorar filas de estado vacío que ocupan toda la tabla (colspan)
            return !(row.children.length === 1 && row.children[0].hasAttribute("colspan"));
        });

        let footerEl = typeof options.footerEl === "string"
            ? document.querySelector(options.footerEl)
            : options.footerEl;

        if (!footerEl) {
            const card = tbody.closest(".table-card");
            if (card) {
                footerEl = document.createElement("div");
                footerEl.className = "table-footer";
                card.appendChild(footerEl);
            }
        }

        const state = {
            page: 1,
            pageSize: options.pageSize || 10
        };

        function getFilteredRows() {
            if (typeof options.filterFn !== "function") {
                return allRows;
            }
            return allRows.filter(options.filterFn);
        }

        function render() {
            const matching = getFilteredRows();
            const totalPages = Math.max(1, Math.ceil(matching.length / state.pageSize));
            if (state.page > totalPages) {
                state.page = totalPages;
            }

            const start = (state.page - 1) * state.pageSize;
            const end = start + state.pageSize;
            const visibleSet = new Set(matching.slice(start, end));

            allRows.forEach(function (row) {
                row.style.display = visibleSet.has(row) ? "" : "none";
            });

            renderControls(footerEl, {
                totalItems: matching.length,
                page: state.page,
                pageSize: state.pageSize,
                label: options.label || "registros",
                onPageChange: function (newPage) {
                    state.page = newPage;
                    render();
                },
                onPageSizeChange: function (newSize) {
                    state.pageSize = newSize;
                    state.page = 1;
                    render();
                }
            });
        }

        const filterInputs = options.filterInputs || [];
        filterInputs.forEach(function (inputRef) {
            const el = typeof inputRef === "string"
                ? document.querySelector(inputRef)
                : inputRef;
            if (!el) return;
            const evt = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(evt, function () {
                state.page = 1;
                render();
            });
        });

        render();

        return {
            render: render,
            resetAndRender: function () {
                state.page = 1;
                render();
            }
        };
    }

    global.LumynPagination = {
        renderControls: renderControls,
        attachTable: attachTable
    };
})(window);
