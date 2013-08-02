# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/llvm/llvm-3.3-r1.ebuild,v 1.1 2013/07/21 10:00:50 mgorny Exp $

EAPI=5

PYTHON_COMPAT=( python{2_5,2_6,2_7} pypy{1_9,2_0} )

inherit eutils flag-o-matic multilib python-r1 toolchain-funcs pax-utils

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI="http://llvm.org/releases/${PV}/${P}.src.tar.gz
	clang? ( http://llvm.org/releases/${PV}/compiler-rt-${PV}.src.tar.gz
		http://llvm.org/releases/${PV}/cfe-${PV}.src.tar.gz )
	!doc? ( http://dev.gentoo.org/~voyageur/distfiles/${P}-manpages.tar.bz2 )"

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="clang debug doc gold kernel_FreeBSD +libffi multitarget ocaml python
	+static-analyzer test udis86 video_cards_radeon +abi-wrapper"

DEPEND="dev-lang/perl
	>=sys-devel/make-3.79
	>=sys-devel/flex-2.5.4
	>=sys-devel/bison-1.875d
	|| ( >=sys-devel/gcc-3.0 >=sys-devel/gcc-apple-4.2.1 )
	|| ( >=sys-devel/binutils-2.18 >=sys-devel/binutils-apple-3.2.3 )
	sys-libs/zlib
	doc? ( dev-python/sphinx )
	gold? ( >=sys-devel/binutils-2.22[cxx] )
	libffi? ( virtual/pkgconfig
		virtual/libffi )
	ocaml? ( dev-lang/ocaml )
	udis86? ( dev-libs/udis86[pic(+)] )
	${PYTHON_DEPS}"
RDEPEND="dev-lang/perl
	libffi? ( virtual/libffi )
	clang? ( python? ( ${PYTHON_DEPS} ) )
	udis86? ( dev-libs/udis86[pic(+)] )
	clang? ( !<=sys-devel/clang-3.3-r99
		!>=sys-devel/clang-9999 )
	multilib_abi_x86? ( !<app-emulation/emul-linux-x86-baselibs-99999999
		!<app-emulation/emul-linux-x86-baselibs-99999999 )"

# pypy gives me around 1700 unresolved tests due to open file limit
# being exceeded. probably GC does not close them fast enough.
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	test? ( || ( $(python_gen_useflags 'python*') ) )"

S=${WORKDIR}/${P}.src

pkg_setup() {
	# need to check if the active compiler is ok

	broken_gcc=" 3.2.2 3.2.3 3.3.2 4.1.1 "
	broken_gcc_x86=" 3.4.0 3.4.2 "
	broken_gcc_amd64=" 3.4.6 "

	gcc_vers=$(gcc-fullversion)

	if [[ ${broken_gcc} == *" ${version} "* ]] ; then
		elog "Your version of gcc is known to miscompile llvm."
		elog "Check http://www.llvm.org/docs/GettingStarted.html for"
		elog "possible solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	fi

	if [[ ${CHOST} == i*86-* && ${broken_gcc_x86} == *" ${version} "* ]] ; then
		elog "Your version of gcc is known to miscompile llvm on x86"
		elog "architectures.  Check"
		elog "http://www.llvm.org/docs/GettingStarted.html for possible"
		elog "solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	fi

	if [[ ${CHOST} == x86_64-* && ${broken_gcc_amd64} == *" ${version} "* ]];
	then
		elog "Your version of gcc is known to miscompile llvm in amd64"
		elog "architectures.  Check"
		elog "http://www.llvm.org/docs/GettingStarted.html for possible"
		elog "solutions."
		die "Your currently active version of gcc is known to miscompile llvm"
	fi
}

src_unpack() {
	default

	rm -f "${S}"/tools/clang "${S}"/projects/compiler-rt \
		|| die "symlinks removal failed"

	if use clang; then
		mv "${WORKDIR}"/cfe-${PV}.src "${S}"/tools/clang \
			|| die "clang source directory move failed"
		mv "${WORKDIR}"/compiler-rt-${PV}.src "${S}"/projects/compiler-rt \
			|| die "compiler-rt source directory move failed"
	fi
}

src_prepare() {
	if use clang; then
		# Automatically select active system GCC's libraries, bugs #406163 and #417913
		epatch "${FILESDIR}"/clang-3.1-gentoo-runtime-gcc-detection-v3.patch

		# Fix search paths on FreeBSD, bug #409269
		# This patch causes problem for multilib on fbsd, see comments in the patch
		# (aballier@g.o)
		# epatch "${FILESDIR}"/clang-3.1-gentoo-freebsd-fix-lib-path.patch

		# Fix regression caused by removal of USE=system-cxx-headers, bug #417541
		# Needs to be updated for 3.2
		#epatch "${FILESDIR}"/clang-3.1-gentoo-freebsd-fix-cxx-paths-v2.patch
	fi

	epatch "${FILESDIR}"/${PN}-3.2-nodoctargz.patch
	epatch "${FILESDIR}"/${P}-R600_debug.patch
	epatch "${FILESDIR}"/${PN}-3.3-gentoo-install.patch
	use clang && epatch "${FILESDIR}"/clang-3.3-gentoo-install.patch

	# Fix insecure RPATHs that were removed upstream already.
	epatch "${FILESDIR}"/${P}-insecure-rpath.patch

	local sub_files=(
		Makefile.config.in
		Makefile.rules
		tools/llvm-config/llvm-config.cpp
	)
	use clang && sub_files+=(
		tools/clang/lib/Driver/Tools.cpp
		tools/clang/tools/scan-build/scan-build
	)

	# unfortunately ./configure won't listen to --mandir and the-like, so take
	# care of this.
	# note: we're setting the main libdir intentionally.
	# where per-ABI is appropriate, we use $(GENTOO_LIBDIR) make.
	einfo "Fixing install dirs"
	sed -e "s,@libdir@,$(get_libdir),g" \
		-e "s,@PF@,${PF},g" \
		-e "s,@EPREFIX@,${EPREFIX},g" \
		-i "${sub_files[@]}" \
		|| die "install paths sed failed"

	# User patches
	epatch_user
}

llvm_add_ldpath() {
	# Add LLVM built libraries to LD_LIBRARY_PATH.
	# This way we don't have to hack RPATHs of executables.
	local libpath
	if use debug; then
		libpath=${BUILD_DIR}/Debug+Asserts+Checks/lib
	else
		libpath=${BUILD_DIR}/Release/lib
	fi

	export LD_LIBRARY_PATH=${libpath}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
}

src_configure() {
	local CONF_FLAGS="--enable-keep-symbols
		--enable-shared
		--with-optimize-option=
		$(use_enable !debug optimized)
		$(use_enable debug assertions)
		$(use_enable debug expensive-checks)"

	if use clang; then
		CONF_FLAGS+="
			--with-clang-resource-dir=../lib/clang/${PV}"
	fi

	if use multitarget; then
		CONF_FLAGS="${CONF_FLAGS} --enable-targets=all"
	else
		CONF_FLAGS="${CONF_FLAGS} --enable-targets=host,cpp"
	fi

	if [[ ${ABI} == amd64 ]]; then
		CONF_FLAGS="${CONF_FLAGS} --enable-pic"
	fi

	if [[ ${ABI} == ${DEFAULT_ABI} ]] && use gold; then
		CONF_FLAGS="${CONF_FLAGS} --with-binutils-include=${EPREFIX}/usr/include/"
	fi
	if [[ ${ABI} == ${DEFAULT_ABI} ]] && use ocaml; then
		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=ocaml"
	else
		CONF_FLAGS="${CONF_FLAGS} --enable-bindings=none"
	fi

	if use udis86; then
		CONF_FLAGS="${CONF_FLAGS} --with-udis86"
	fi

	if use video_cards_radeon; then
		CONF_FLAGS="${CONF_FLAGS}
		--enable-experimental-targets=R600"
	fi

	if use libffi; then
		append-cppflags "$(pkg-config --cflags libffi)"
	fi
	CONF_FLAGS="${CONF_FLAGS} $(use_enable libffi)"

	# build with a suitable Python version
	python_export_best

	# llvm prefers clang over gcc, so we may need to force that
	tc-export CC CXX

	ECONF_SOURCE=${S} \
	econf ${CONF_FLAGS}
}

src_compile() {
	local mymakeopts=(
		VERBOSE=1
		REQUIRES_RTTI=1
		GENTOO_LIBDIR="$(get_libdir)"
	)

	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
	llvm_add_ldpath

	# Tests need all the LLVM built.
	if [[ ${ABI} == ${DEFAULT_ABI} ]] || use test; then
		emake "${mymakeopts[@]}"
	else
		# we need to build libs for llvm, then whole clang,
		# since libs-only omits clang dir
		# and clang fails to sub-compile with libs-only.
		emake "${mymakeopts[@]}" libs-only
		use clang && emake -C tools/clang "${mymakeopts[@]}"
	fi

	if [[ ${ABI} == ${DEFAULT_ABI} ]] && use doc; then
		emake -C "${S}"/docs -f Makefile.sphinx man html
	fi

	if use debug; then
		pax-mark m Debug+Asserts+Checks/bin/llvm-rtdyld
		pax-mark m Debug+Asserts+Checks/bin/lli
	else
		pax-mark m Release/bin/llvm-rtdyld
		pax-mark m Release/bin/lli
	fi
	if use test; then
		pax-mark m unittests/ExecutionEngine/JIT/Release/JITTests
		pax-mark m unittests/ExecutionEngine/MCJIT/Release/MCJITTests
		pax-mark m unittests/Support/Release/SupportTests
	fi
}

src_test() {
	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
	llvm_add_ldpath

	default

	use clang && emake -C tools/clang test
}

src_install() {
	local mymakeopts=(
		DESTDIR="${D}"
		GENTOO_LIBDIR="$(get_libdir)"
	)

	local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
	llvm_add_ldpath

	if [[ ${ABI} == ${DEFAULT_ABI} ]]; then
		emake "${mymakeopts[@]}" install

		# Move files back.
		#if path_exists -o "${ED}"/tmp/llvm-config.*; then
		#	mv "${ED}"/tmp/llvm-config.* "${ED}"/usr/bin || die
		#fi
	else
		# we need to install libs for llvm, then whole clang
		# since libs-only omits clang dir
		# and clang install-libs doesn't install headers and stuff
		# (we build it anyway, so install is not a problem)
		emake "${mymakeopts[@]}" install-libs
		use clang && emake -C tools/clang "${mymakeopts[@]}" install

		# Preserve ABI-variant of llvm-config,
		# then drop all the executables since LLVM doesn't like to
		# clobber when installing.
		#mkdir -p "${ED}"/tmp || die
		#mv "${ED}"/usr/bin/llvm-config "${ED}"/tmp/llvm-config.${ABI} || die
		#rm -r "${ED}"/usr/bin || die
	fi

	# Fix install_names on Darwin.  The build system is too complicated
	# to just fix this, so we correct it post-install
	local lib= f= odylib= libpv=${PV}
	if [[ ${CHOST} == *-darwin* ]] ; then
		eval $(grep PACKAGE_VERSION= configure)
		[[ -n ${PACKAGE_VERSION} ]] && libpv=${PACKAGE_VERSION}
		for lib in lib{EnhancedDisassembly,LLVM-${libpv},LTO,profile_rt,clang}.dylib {BugpointPasses,LLVMHello}.dylib ; do
			# libEnhancedDisassembly is Darwin10 only, so non-fatal
			# + omit clang libs if not enabled
			[[ -f ${ED}/usr/lib/${PN}/${lib} ]] || continue

			ebegin "fixing install_name of $lib"
			install_name_tool \
				-id "${EPREFIX}"/usr/lib/${PN}/${lib} \
				"${ED}"/usr/lib/${PN}/${lib}
			eend $?
		done
		for f in "${ED}"/usr/bin/* "${ED}"/usr/lib/${PN}/lib{LTO,clang}.dylib ; do
			# omit clang libs if not enabled
			[[ -f ${ED}/usr/lib/${PN}/${lib} ]] || continue

			odylib=$(scanmacho -BF'%n#f' "${f}" | tr ',' '\n' | grep libLLVM-${libpv}.dylib)
			ebegin "fixing install_name reference to ${odylib} of ${f##*/}"
			install_name_tool \
				-change "${odylib}" \
					"${EPREFIX}"/usr/lib/${PN}/libLLVM-${libpv}.dylib \
				-change "@rpath/libclang.dylib" \
					"${EPREFIX}"/usr/lib/llvm/libclang.dylib \
				-change "${S}"/Release/lib/libclang.dylib \
					"${EPREFIX}"/usr/lib/llvm/libclang.dylib \
				"${f}"
			eend $?
		done
	fi
	if use doc; then
		doman docs/_build/man/*.1
		dohtml -r docs/_build/html/
	else
		doman "${WORKDIR}"/${P}-manpages/*.1
	fi

	insinto /usr/share/vim/vimfiles/syntax
	doins utils/vim/*.vim

	if use clang; then
		cd tools/clang || die

		if use static-analyzer ; then
			dobin tools/scan-build/ccc-analyzer
			dosym ccc-analyzer /usr/bin/c++-analyzer
			dobin tools/scan-build/scan-build

			insinto /usr/share/${PN}
			doins tools/scan-build/scanview.css
			doins tools/scan-build/sorttable.js
		fi

		python_inst() {
			if use static-analyzer ; then
				pushd tools/scan-view >/dev/null || die

				python_doscript scan-view

				touch __init__.py || die
				python_moduleinto clang
				python_domodule __init__.py Reporter.py Resources ScanView.py startfile.py

				popd >/dev/null || die
			fi

			if use python ; then
				pushd bindings/python/clang >/dev/null || die

				python_moduleinto clang
				python_domodule __init__.py cindex.py enumerations.py

				popd >/dev/null || die
			fi

			# AddressSanitizer symbolizer (currently separate)
			python_doscript "${S}"/projects/compiler-rt/lib/asan/scripts/asan_symbolize.py
		}
		python_foreach_impl python_inst
	fi

	# Remove unnecessary headers on FreeBSD, bug #417171
	use kernel_FreeBSD && use clang && rm "${ED}"usr/lib/clang/${PV}/include/{arm_neon,std,float,iso,limits,tgmath,varargs}*.h
}
