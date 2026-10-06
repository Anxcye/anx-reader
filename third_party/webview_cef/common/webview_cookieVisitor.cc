#include "webview_cookieVisitor.h"

WebviewCookieVisitor::WebviewCookieVisitor()
{
}

WebviewCookieVisitor::~WebviewCookieVisitor()
{
}
void WebviewCookieVisitor::setOnVisitComplete(std::function<void(std::map<std::string, std::map<std::string, std::string>>)> complete)
{
    onVisitComplete = complete;
}

bool WebviewCookieVisitor::Visit(const CefCookie &cookie, int count, int total, bool &deleteCookie)
{
    {
        std::unique_lock<std::mutex> lock(m_mutexCookieVector);
	    if (count == 0)
	    {
		    m_vecAllCookies.clear();
	    }
        		
        m_vecAllCookies.emplace_back(cookie);
    }

    if(count == total - 1)
    {
        onVisitComplete(getVisitedCookies());
    }

    return count != total;
}

std::map<std::string, std::map<std::string, std::string>> WebviewCookieVisitor::getVisitedCookies()
{
    std::map<std::string, std::map<std::string, std::string>> ret;
    for (auto &cookie : m_vecAllCookies)
    {
        ;
        std::string domain = CefString(cookie.domain.str).ToString();
        std::string name = CefString(cookie.name.str).ToString();
        std::string value = CefString(cookie.value.str).ToString();
        ret[domain][name] = value;
    }
    return ret;
}
