<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="org.jivesoftware.openfire.XMPPServer,
                 org.jivesoftware.openfire.user.User,
                 org.jivesoftware.openfire.user.UserManager,
                 org.jivesoftware.util.ParamUtils,
                 org.xmpp.packet.JID,
                 java.util.*"
%>

<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="admin" prefix="admin" %>
<html>
<head>
    <title><fmt:message key="advance.user.search.title"/></title>
    <meta name="pageID" content="advance-user-search"/>
</head>
<body>

<%
    String criteria = ParamUtils.getParameter( request, "criteria" );
    boolean moreOptions = ParamUtils.getBooleanParameter( request, "moreOptions", false );

    UserManager userManager = UserManager.getInstance();
    Set<String> searchFields = userManager.getSearchFields();
    List<String> selectedFields = new ArrayList<>();

    Set<User> users = new HashSet<>();

    if ( criteria != null )
    {
        for ( String searchField : searchFields )
        {
            boolean searchValue = ParamUtils.getBooleanParameter( request, searchField, false );
            if ( !moreOptions || searchValue )
            {
                selectedFields.add( searchField );
                Collection<User> foundUsers = userManager.findUsers( Collections.singleton( searchField ), criteria );

                for ( User user : foundUsers )
                {
                    if ( user != null )
                    {
                        users.add( user );
                    }
                }
            }
        }
    }

    pageContext.setAttribute( "criteria", criteria );
    pageContext.setAttribute( "moreOptions", moreOptions );
    pageContext.setAttribute( "searchFields", searchFields );
    pageContext.setAttribute( "selectedFields", selectedFields );
    pageContext.setAttribute( "users", users );
    pageContext.setAttribute( "presenceManager", XMPPServer.getInstance().getPresenceManager() );
    pageContext.setAttribute( "readOnly", UserManager.getUserProvider().isReadOnly() );
%>

<form name="f" action="advance-user-search.jsp">
    <input type="hidden" name="search" value="true"/>
    <input type="hidden" name="moreOptions" value="${fn:escapeXml(moreOptions)}"/>

    <div class="jive-contentBoxHeader"><fmt:message key="advance.user.search.search_user"/></div>
    <div class="jive-contentBox">
        <table cellpadding="3" cellspacing="1" border="0" width="600">
            <tr class="c1">
                <td width="1%" colspan="2" nowrap>
                    <fmt:message key="advance.user.search.search"/>
                    &nbsp;<input type="text" name="criteria" value="${not empty criteria ? fn:escapeXml(criteria) : ''}" size="30" maxlength="75"/>
                    &nbsp;<input type="submit" name="search" value="<fmt:message key="advance.user.search.search" />"/>
                </td>
            </tr>
            <c:choose>
                <c:when test="${moreOptions}">
                    <tr class="c1">
                        <td width="1%" colspan="2" nowrap style="padding-top: 1em;"><fmt:message key="advance.user.search.details"/></td>
                    </tr>
                    <c:forEach items="${searchFields}" var="searchField">
                        <tr class="c1">
                            <td width="1%" nowrap><label for="${fn:escapeXml(searchField)}"><c:out value="${searchField}"/>:</label></td>
                            <td class="c2">
                                <c:choose>
                                    <c:when test="${empty criteria}">
                                        <input type="checkbox" checked name="${fn:escapeXml(searchField)}" id="${fn:escapeXml(searchField)}"/>
                                    </c:when>
                                    <c:otherwise>
                                        <input type="checkbox" ${selectedFields.contains(searchField) ? 'checked' : ''} name="${fn:escapeXml(searchField)}" id="${fn:escapeXml(searchField)}"/>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                        </tr>
                    </c:forEach>
                    <tr>
                        <td nowrap>&raquo;&nbsp;<a href="advance-user-search.jsp?moreOptions=false"><fmt:message key="advance.user.search.less_options"/></a></td>
                    </tr>
                </c:when>
                <c:otherwise>
                    <tr>
                        <td nowrap>&raquo;&nbsp;<a href="advance-user-search.jsp?moreOptions=true"><fmt:message key="advance.user.search.more_options"/></a></td>
                    </tr>
                </c:otherwise>
            </c:choose>
        </table>
    </div>
</form>

<c:if test="${not empty criteria}">
    <p>
        <fmt:message key="advance.user.search.users_found"/>: <c:out value="${users.size()}"/>
    </p>

    <div class="jive-table">
        <table cellpadding="0" cellspacing="0" border="0" width="100%">
            <thead>
            <tr>
                <th>&nbsp;</th>
                <th nowrap><fmt:message key="advance.user.search.online"/></th>
                <th nowrap><fmt:message key="advance.user.search.username"/></th>
                <th nowrap><fmt:message key="advance.user.search.name"/></th>
                <th nowrap><fmt:message key="advance.user.search.created"/></th>
                <th nowrap><fmt:message key="advance.user.search.last-logout"/></th>
                <!-- Don't allow editing or deleting if users are read-only. -->
                <c:if test="${not readOnly}">
                    <th nowrap><fmt:message key="advance.user.search.edit"/></th>
                    <th nowrap><fmt:message key="advance.user.search.delete"/></th>
                </c:if>
            </tr>
            </thead>
            <tbody>

            <c:choose>
                <c:when test="${empty users}">
                    <tr>
                        <td align="center" colspan="8"><fmt:message key="advance.user.search.no_users"/></td>
                    </tr>
                </c:when>
                <c:otherwise>
                    <c:forEach items="${users}" var="user" varStatus="status">

                        <tr class="jive-${status.count%2==0 ? 'odd' : 'even'}">
                            <td width="1%">
                                <c:out value="${status.count}"/>
                            </td>
                            <td width="1%" align="center" valign="middle">
                                <c:choose>
                                    <c:when test="${presenceManager.isAvailable(user)}">
                                        <c:set var="show" value="${presenceManager.getPresence(user).show}}"/>
                                        <c:choose>
                                            <c:when test="${empty show}">
                                                <img src="images/user-green-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.available" />">
                                            </c:when>
                                            <c:when test="${show.name() eq 'chat'}">
                                                <img src="images/user-green-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.chat_available" />">
                                            </c:when>
                                            <c:when test="${show.name() eq 'away'}">
                                                <img src="images/user-yellow-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.away" />">
                                            </c:when>
                                            <c:when test="${show.name() eq 'xa'}">
                                                <img src="images/user-yellow-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.extended" />">
                                            </c:when>
                                            <c:when test="${show.name() eq 'dnd'}">
                                                <img src="images/user-red-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.not_disturb" />">
                                            </c:when>
                                        </c:choose>
                                    </c:when>
                                    <c:otherwise>
                                        <img src="images/user-clear-16x16.gif" width="16" height="16" border="0" alt="<fmt:message key="advance.user.search.offline" />">
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td width="23%">
                                <a href="../../user-properties.jsp?username=${admin:urlEncode(user.username)}"><c:out value="${JID.unescapeNode(user.username)}"/></a>
                            </td>
                            <td width="33">
                                <c:out value="${user.name}"/>
                            </td>
                            <td width="15%">
                                <c:choose>
                                    <c:when test="${not empty user.creationDate}">
                                        <c:out value="${admin:formatDate(user.creationDate)}"/>
                                    </c:when>
                                    <c:otherwise>
                                        <c:out value="&nbps;"/>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td width="25%">
                                <c:set var="logoutTime" value="${presenceManager.getLastActivity(user)}"/>
                                <c:choose>
                                    <c:when test="${not empty logoutTime and logoutTime gt -1}">
                                        <c:out value="${admin:elapsedTime(logoutTime)}"/>
                                    </c:when>
                                    <c:otherwise>
                                        <c:out value="&nbps;"/>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <!-- Don't allow editing or deleting if users are read-only. -->
                            <c:if test="${not readOnly}">
                                <td width="1%" align="center">
                                    <a href="../../user-edit-form.jsp?username=${admin:urlEncode(user.username)}" title="<fmt:message key="global.click_edit" />"><img src="images/edit-16x16.gif" width="17" height="17" border="0"></a>
                                </td>
                                <td width="1%" align="center" style="border-right:1px #ccc solid;">
                                    <a href="../../user-delete.jsp?username=${admin:urlEncode(user.username)}" title="<fmt:message key="global.click_delete" />"><img src="images/delete-16x16.gif" width="16" height="16" border="0"></a>
                                </td>
                            </c:if>
                        </tr>
                    </c:forEach>
                </c:otherwise>
            </c:choose>

            </tbody>
        </table>
    </div>

</c:if>

<script language="JavaScript" type="text/javascript">
    document.f.criteria.focus();
</script>

</body>
</html>
