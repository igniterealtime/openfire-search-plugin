<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*,
                 org.jivesoftware.openfire.XMPPServer,
                 org.jivesoftware.openfire.plugin.SearchPlugin,
                 org.jivesoftware.openfire.user.*,
                 org.jivesoftware.util.*"
%>

<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="admin" prefix="admin" %>

<%  // Get parameters
    boolean save = request.getParameter("save") != null;
    boolean success = request.getParameter("success") != null;
    String searchName = ParamUtils.getParameter(request, "searchname");
    boolean searchEnabled = ParamUtils.getBooleanParameter(request, "searchEnabled");
    boolean groupOnly = ParamUtils.getBooleanParameter(request, "groupOnly");
    
    SearchPlugin plugin = (SearchPlugin) XMPPServer.getInstance().getPluginManager().getPluginByName("Search").orElseThrow();

    // Handle a save
    Map<String,String> errors = new HashMap<>();

    Cookie csrfCookie = CookieUtils.getCookie(request, "csrf");
    String csrfParam = ParamUtils.getParameter(request, "csrf");

    if (save) {
        if (csrfCookie == null || csrfParam == null || !csrfCookie.getValue().equals(csrfParam)) {
            save = false;
            errors.put("csrf", "CSRF Failure!");
        }
    }
    csrfParam = StringUtils.randomString(15);
    CookieUtils.setCookie(request, response, "csrf", csrfParam, -1);
    pageContext.setAttribute("csrf", csrfParam);

    if (save) {
        if (searchName == null || searchName.indexOf('.') >= 0 || searchName.trim().length() < 1) {
            errors.put("searchname", "searchname");
        }
        else {
            if (errors.size() == 0) {
                plugin.setServiceEnabled(searchEnabled);
                plugin.setServiceName(searchName.trim());

                ArrayList<String> excludedFields = new ArrayList<>();
                for (String field : UserManager.getInstance().getSearchFields()) {
                    if (!ParamUtils.getBooleanParameter(request, field)) {
                         excludedFields.add(field);
                    }
                }
                plugin.setExcludedFields(excludedFields);
                plugin.setGroupOnly(groupOnly);
                response.sendRedirect("search-props-edit-form.jsp?success=true");
                return;
            }
        }
    }
    else {
        searchName = plugin.getServiceName();
    }

    if (errors.size() == 0) {
        searchName = plugin.getServiceName();
    }
    
    searchEnabled = plugin.getServiceEnabled();
    Collection<String> searchableFields = plugin.getFilteredSearchFields();
    groupOnly = plugin.isGroupOnly();

    pageContext.setAttribute( "errors", errors );
    pageContext.setAttribute( "success", success );
    pageContext.setAttribute( "searchEnabled", searchEnabled );
    pageContext.setAttribute( "searchName", searchName );
    pageContext.setAttribute( "availableSearchFields", UserManager.getInstance().getSearchFields() );
    pageContext.setAttribute( "searchableFields", searchableFields );
    pageContext.setAttribute( "groupOnly", groupOnly );
    pageContext.setAttribute( "xmppDomain", XMPPServer.getInstance().getServerInfo().getXMPPDomain() );
%>

<html>
    <head>
        <title><fmt:message key="search.props.edit.form.title" /></title>
        <meta name="pageID" content="search-props-edit-form"/>
    </head>
    <body>

    <p>
        <fmt:message key="search.props.edit.form.directions" />
    </p>

    <c:choose>
        <c:when test="${not empty errors}">
            <admin:infobox type="error"><fmt:message key="search.props.edit.form.error" /></admin:infobox>
        </c:when>
        <c:when test="${success}">
            <admin:infobox type="success"><fmt:message key="search.props.edit.form.successful_edit" /></admin:infobox>
        </c:when>
    </c:choose>

    <form action="search-props-edit-form.jsp?save" method="post">
    <input type="hidden" name="csrf" value="${csrf}">

    <fmt:message key="search.props.edit.form.service_enabled" var="serviceEnabledBoxtitle"/>
    <admin:contentBox title="${serviceEnabledBoxtitle}">

    <p>
    <fmt:message key="search.props.edit.form.service_enabled_directions" />
    </p>
    <table cellpadding="3" cellspacing="0" border="0" width="100%">
    <tbody>
        <tr>
            <td width="1%">
                <input type="radio" name="searchEnabled" value="true" id="rb01" ${searchEnabled ? 'checked' : ''}>
            </td>
            <td width="99%">
                <label for="rb01"><b><fmt:message key="search.props.edit.form.enabled" /></b></label> - <fmt:message key="search.props.edit.form.enabled_details" />
            </td>
        </tr>
        <tr>
            <td width="1%">
                <input type="radio" name="searchEnabled" value="false" id="rb02" ${not searchEnabled ? 'checked' : ''}>
            </td>
            <td width="99%">
                <label for="rb02"><b><fmt:message key="search.props.edit.form.disabled" /></b></label> - <fmt:message key="search.props.edit.form.disabled_details" />
            </td>
        </tr>
    </tbody>
    </table>
    </admin:contentBox>

    <fmt:message key="search.props.edit.form.service_name" var="serviceNameBoxtitle"/>
    <admin:contentBox title="${serviceNameBoxtitle}">
    <table cellpadding="3" cellspacing="0" border="0">
    <tr>
        <td class="c1">
            <label for="searchname">
                <fmt:message key="search.props.edit.form.search_service_name" />:
            </label>
        </td>
        <td>
            <input type="text" size="30" maxlength="150" name="searchname" id="searchname" value="${not empty searchName ? fn:escapeXml(searchName) : ''}">.<c:out value="${xmppDomain}"/>

            <c:if test="${errors.containsKey('searchname')}">
                <span class="jive-error-text">
                <br><fmt:message key="search.props.edit.form.search_service_name_details" />
                </span>
            </c:if>
        </td>
    </tr>
    </table>
    </admin:contentBox>

    <fmt:message key="search.props.edit.form.searchable_fields" var="fieldsBoxtitle"/>
    <admin:contentBox title="${fieldsBoxtitle}">
    <p>
    <fmt:message key="search.props.edit.form.searchable_fields_details" />
    </p>
    <table class="jive-table" cellpadding="3" cellspacing="0" border="0" width="400">
        <tr>
            <th align="center" width="1%"><fmt:message key="search.props.edit.form.enabled" /></th>
            <th align="left" width="99%"><fmt:message key="search.props.edit.form.fields" /></th>
        </tr>
        <c:forEach items="${availableSearchFields}" var="field">
            <tr>
                <td align="center" width="1%"><input type="checkbox" ${searchableFields.contains( field ) ? 'checked' : ''} name="${fn:escapeXml(field)}" id="${fn:escapeXml(field)}"></td>
                <td align="left" width="99%"><label for="${fn:escapeXml(field)}"><c:out value="${field}"/></label></td>
            </tr>
        </c:forEach>
    </table>
    </admin:contentBox>

<br>

<div class="jive-contentBoxHeader"><fmt:message key="search.props.edit.form.search_scope" /></div>
<div class="jive-contentBox">
    <p>
    <fmt:message key="search.props.edit.form.search_scope_directions" />
    </p>
    <table cellpadding="3" cellspacing="0" border="0" width="100%">
    <tbody>
        <tr>
            <td width="1%">
                <input type="radio" name="groupOnly" value="false" id="rb-grouponly-01" ${not groupOnly ? 'checked' : ''}>
            </td>
            <td width="99%">
                <label for="rb-grouponly-01"><b><fmt:message key="search.props.edit.form.search_scope_anyone" /></b></label> - <fmt:message key="search.props.edit.form.search_scope_anyone_details" />
            </td>
        </tr>
        <tr>
            <td width="1%">
                <input type="radio" name="groupOnly" value="true" id="rb-grouponly-02" ${groupOnly ? 'checked' : ''}>
            </td>
            <td width="99%">
                <label for="rb-grouponly-02"><b><fmt:message key="search.props.edit.form.search_scope_groups" /></b></label> - <fmt:message key="search.props.edit.form.search_scope_groups_details" />
            </td>
        </tr>
    </tbody>
    </table>
</div>

<br>


<input type="submit" value="<fmt:message key="search.props.edit.form.save_properties" />">
</form>

</body>
</html>
