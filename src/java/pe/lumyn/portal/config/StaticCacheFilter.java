package pe.lumyn.portal.config;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Habilita caché HTTP para recursos estáticos (CSS y JS) reduciendo
 * peticiones redundantes en cada navegación dentro del portal.
 */
@WebFilter(urlPatterns = {"/css/*", "/js/*"})
public class StaticCacheFilter implements Filter {

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain) throws IOException, ServletException {

        if (response instanceof HttpServletResponse httpResponse) {
            httpResponse.setHeader("Cache-Control", "public, max-age=86400");
        }
        chain.doFilter(request, response);
    }
}
